#ifndef VECTOR_CONTROLLER_H
#define VECTOR_CONTROLLER_H

#include "vector3d.h"

#include <QObject>
#include <QString>
#include <QVector3D>

// Связующий класс между Vector3D (расчёты) и интерфейсом
// (форма Qt Designer + 3D-сцена QML). Все вычисления выполняются
// перегруженными операциями Vector3D: +, -, *, ==.
class VectorController : public QObject {
    Q_OBJECT
    // Свойства, доступные из QML как calc.drone_velocity и т.д.
    Q_PROPERTY(int mode READ get_mode WRITE set_mode NOTIFY changed)
    Q_PROPERTY(QVector3D drone_velocity READ get_drone_velocity NOTIFY changed)
    Q_PROPERTY(QVector3D wind_velocity READ get_wind_velocity NOTIFY changed)
    Q_PROPERTY(QVector3D ground_velocity READ get_ground_velocity NOTIFY changed)
    Q_PROPERTY(QVector3D correction READ get_correction NOTIFY changed)
    Q_PROPERTY(double correction_factor READ get_correction_factor NOTIFY changed)
    Q_PROPERTY(QVector3D start_point READ get_start_point NOTIFY changed)
    Q_PROPERTY(QVector3D finish_point READ get_finish_point NOTIFY changed)
    Q_PROPERTY(QVector3D displacement READ get_displacement NOTIFY changed)
    Q_PROPERTY(bool check_ok READ is_check_ok NOTIFY changed)

public:
    explicit VectorController(QObject* parent = nullptr);

    // Текст вектора через перегруженный operator<<, например "(12.00, 3.00, -1.00)"
    static QString to_text(const Vector3D& vector);

    int get_mode() const;
    QVector3D get_drone_velocity() const;
    QVector3D get_wind_velocity() const;
    QVector3D get_ground_velocity() const;
    QVector3D get_correction() const;
    double get_correction_factor() const;
    QVector3D get_start_point() const;
    QVector3D get_finish_point() const;
    QVector3D get_displacement() const;
    bool is_check_ok() const;

    const Vector3D& ground() const;
    const Vector3D& autopilot_correction() const;
    const Vector3D& route_displacement() const;
    const Vector3D& route_check() const;

public slots:
    void set_mode(int new_mode);
    void set_wind_task(const QVector3D& drone, const QVector3D& wind, double factor);
    void set_route_task(const QVector3D& start, const QVector3D& finish);
    void request_animation();

signals:
    void changed();
    void animationRequested();

private:
    int mode;

    // Вариант 1: скорость БПЛА
    Vector3D drone_velocity;
    Vector3D wind_velocity;
    Vector3D ground_velocity;
    Vector3D correction;
    double correction_factor;

    // Вариант 2: перемещение по маршруту
    Vector3D start_point;
    Vector3D finish_point;
    Vector3D displacement;
    Vector3D check_point;
    bool check_ok;
};

#endif
