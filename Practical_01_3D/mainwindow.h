#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

class DroneController;

QT_BEGIN_NAMESPACE
namespace Ui {
class MainWindow;
}
QT_END_NAMESPACE

// Главное окно. Внешний вид описан в mainwindow.ui (Qt Designer),
// здесь только связь кнопок с контроллером и обновление панели.
class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget* parent = nullptr);
    ~MainWindow() override;

private slots:
    void update_panel();
    void append_log(const QString& text, const QString& kind);

private:
    void setup_scene();
    void connect_buttons();

    Ui::MainWindow* ui;
    DroneController* controller;
};

#endif
