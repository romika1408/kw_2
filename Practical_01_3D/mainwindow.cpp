#include "mainwindow.h"
#include "ui_mainwindow.h"

#include "drone_controller.h"

#include <QQmlContext>
#include <QQuickWidget>
#include <QStyle>
#include <QTime>
#include <QVBoxLayout>

MainWindow::MainWindow(QWidget* parent)
    : QMainWindow(parent),
      ui(new Ui::MainWindow),
      controller(new DroneController(this)) {
    ui->setupUi(this);

    setup_scene();
    connect_buttons();

    connect(controller, &DroneController::stateChanged,
            this, &MainWindow::update_panel);
    connect(controller, &DroneController::logMessage,
            this, &MainWindow::append_log);

    append_log("Ground station ready. Drone #1 on the landing pad.", "ok");
    update_panel();
}

MainWindow::~MainWindow() {
    delete ui;
}

// 3D-сцена (scene.qml) встраивается в пустой виджет sceneHost,
// размещённый на форме в Qt Designer. Контроллер передаётся в QML
// под именем "drone".
void MainWindow::setup_scene() {
    auto* scene = new QQuickWidget(ui->sceneHost);
    scene->setResizeMode(QQuickWidget::SizeRootObjectToView);
    scene->rootContext()->setContextProperty("drone", controller);
    scene->setSource(QUrl("qrc:/scene.qml"));

    auto* layout = new QVBoxLayout(ui->sceneHost);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(scene);
}

void MainWindow::connect_buttons() {
    connect(ui->createButton, &QPushButton::clicked, this, [this] {
        controller->create_drone(ui->idSpin->value(),
                                 ui->createBatterySpin->value());
    });
    connect(ui->takeoffButton, &QPushButton::clicked,
            controller, &DroneController::takeoff);
    connect(ui->landButton, &QPushButton::clicked,
            controller, &DroneController::land);
    connect(ui->moveButton, &QPushButton::clicked, this, [this] {
        controller->move_to(ui->xSpin->value(),
                            ui->ySpin->value(),
                            ui->zSpin->value());
    });
    connect(ui->emergencyButton, &QPushButton::clicked,
            controller, &DroneController::emergency_land);
    connect(ui->setBatteryButton, &QPushButton::clicked, this, [this] {
        controller->set_battery(ui->batterySpin->value());
    });
}

void MainWindow::update_panel() {
    const double battery = controller->get_battery();
    const QVector3D position = controller->get_position();

    ui->batteryBar->setValue(qRound(battery));
    ui->batteryBar->setFormat(QString::number(battery, 'f', 1) + " %");

    // Цвет полосы задаётся в таблице стилей формы по свойству level
    QString level = "normal";
    if (battery < 10.0) {
        level = "critical";
    } else if (battery < 20.0) {
        level = "low";
    }
    ui->batteryBar->setProperty("level", level);
    ui->batteryBar->style()->unpolish(ui->batteryBar);
    ui->batteryBar->style()->polish(ui->batteryBar);

    ui->idValue->setText(QString("#%1").arg(controller->get_id()));
    ui->positionValue->setText(QString("(%1, %2, %3) m")
                                   .arg(position.x(), 0, 'f', 1)
                                   .arg(position.y(), 0, 'f', 1)
                                   .arg(position.z(), 0, 'f', 1));

    const bool flying = controller->is_flying();
    ui->statusValue->setText(flying ? "FLYING" : "ON GROUND");
    ui->statusValue->setProperty("flying", flying);
    ui->statusValue->style()->unpolish(ui->statusValue);
    ui->statusValue->style()->polish(ui->statusValue);
}

void MainWindow::append_log(const QString& text, const QString& kind) {
    QString color = "#7ee787";
    if (kind == "error") {
        color = "#ff7b72";
    } else if (kind == "warning") {
        color = "#ffa657";
    }
    ui->logView->append(QString("<span style='color:#6e7681'>%1</span> "
                                "<span style='color:%2'>%3</span>")
                            .arg(QTime::currentTime().toString("hh:mm:ss"),
                                 color,
                                 text.toHtmlEscaped()));
}
