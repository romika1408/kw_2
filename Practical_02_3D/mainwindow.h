#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

class VectorController;

QT_BEGIN_NAMESPACE
namespace Ui {
class MainWindow;
}
QT_END_NAMESPACE

// Главное окно. Внешний вид описан в mainwindow.ui (Qt Designer),
// здесь только передача введённых чисел в контроллер и вывод результатов.
class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget* parent = nullptr);
    ~MainWindow() override;

private slots:
    void send_wind_task();
    void send_route_task();
    void update_results();

private:
    void setup_scene();
    void connect_inputs();

    Ui::MainWindow* ui;
    VectorController* controller;
};

#endif
