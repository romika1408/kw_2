#include "mainwindow.h"

#include <QApplication>

// Практическое занятие №2, задание 1, варианты 1 и 2: класс Vector3D.
// Графическая версия: форма Qt Designer + 3D-сцена Qt Quick 3D.
int main(int argc, char* argv[]) {
    QApplication app(argc, argv);

    MainWindow window;
    window.showMaximized();

    return app.exec();
}
