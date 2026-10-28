#include "mainwindow.h"
#include "ui_mainwindow.h"

#include "vector_controller.h"

#include <QDoubleSpinBox>
#include <QQmlContext>
#include <QQuickWidget>
#include <QStyle>
#include <QVBoxLayout>

MainWindow::MainWindow(QWidget* parent)
    : QMainWindow(parent),
      ui(new Ui::MainWindow),
      controller(new VectorController(this)) {
    ui->setupUi(this);

    setup_scene();
    connect_inputs();

    connect(controller, &VectorController::changed,
            this, &MainWindow::update_results);

    send_wind_task();
    send_route_task();
}

MainWindow::~MainWindow() {
    delete ui;
}

// 3D-сцена (scene.qml) встраивается в пустой виджет sceneHost формы.
// Контроллер передаётся в QML под именем "calc".
void MainWindow::setup_scene() {
    auto* scene = new QQuickWidget(ui->sceneHost);
    scene->setResizeMode(QQuickWidget::SizeRootObjectToView);
    scene->rootContext()->setContextProperty("calc", controller);
    scene->setSource(QUrl("qrc:/scene.qml"));

    auto* layout = new QVBoxLayout(ui->sceneHost);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(scene);
}

void MainWindow::connect_inputs() {
    const QList<QDoubleSpinBox*> wind_inputs = {
        ui->droneXSpin, ui->droneYSpin, ui->droneZSpin,
        ui->windXSpin, ui->windYSpin, ui->windZSpin,
        ui->factorSpin
    };
    for (QDoubleSpinBox* spin : wind_inputs) {
        connect(spin, &QDoubleSpinBox::valueChanged,
                this, &MainWindow::send_wind_task);
    }

    const QList<QDoubleSpinBox*> route_inputs = {
        ui->startXSpin, ui->startYSpin, ui->startZSpin,
        ui->finishXSpin, ui->finishYSpin, ui->finishZSpin
    };
    for (QDoubleSpinBox* spin : route_inputs) {
        connect(spin, &QDoubleSpinBox::valueChanged,
                this, &MainWindow::send_route_task);
    }

    // Вкладка формы определяет, какой вариант показывает 3D-сцена
    connect(ui->taskTabs, &QTabWidget::currentChanged,
            controller, &VectorController::set_mode);
    connect(ui->animateButton, &QPushButton::clicked,
            controller, &VectorController::request_animation);
}

void MainWindow::send_wind_task() {
    controller->set_wind_task(
        QVector3D(ui->droneXSpin->value(), ui->droneYSpin->value(), ui->droneZSpin->value()),
        QVector3D(ui->windXSpin->value(), ui->windYSpin->value(), ui->windZSpin->value()),
        ui->factorSpin->value());
}

void MainWindow::send_route_task() {
    controller->set_route_task(
        QVector3D(ui->startXSpin->value(), ui->startYSpin->value(), ui->startZSpin->value()),
        QVector3D(ui->finishXSpin->value(), ui->finishYSpin->value(), ui->finishZSpin->value()));
}

void MainWindow::update_results() {
    // Вариант 1
    const Vector3D& ground = controller->ground();
    const Vector3D& correction = controller->autopilot_correction();
    ui->groundValue->setText(VectorController::to_text(ground) + " м/с");
    ui->speedValue->setText(QString::number(ground.length(), 'f', 2) + " м/с");
    ui->correctionValue->setText(VectorController::to_text(correction));
    ui->correctionLengthValue->setText(QString::number(correction.length(), 'f', 2));

    // Вариант 2
    const Vector3D& displacement = controller->route_displacement();
    ui->displacementValue->setText(VectorController::to_text(displacement));
    ui->dxValue->setText(QString::number(displacement.get_x(), 'f', 2) + " м");
    ui->dyValue->setText(QString::number(displacement.get_y(), 'f', 2) + " м");
    ui->dzValue->setText(QString::number(displacement.get_z(), 'f', 2) + " м");
    ui->distanceValue->setText(QString::number(displacement.length(), 'f', 2) + " м");

    const bool ok = controller->is_check_ok();
    ui->checkValue->setText(ok ? "✔ start + Δ == finish"
                               : "✘ проверка не пройдена");
    ui->checkValue->setProperty("ok", ok);
    ui->checkValue->style()->unpolish(ui->checkValue);
    ui->checkValue->style()->polish(ui->checkValue);
}
