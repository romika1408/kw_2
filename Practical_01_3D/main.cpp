#include "mainwindow.h"

#include <QApplication>

// Практическое занятие №1, задание 1, вариант 1: управление полётом.
// Графическая версия: форма Qt Designer + 3D-сцена Qt Quick 3D.
int main(int argc, char* argv[]) {
    QApplication app(argc, argv);

    MainWindow window;
    window.showMaximized();

    return app.exec();
}
