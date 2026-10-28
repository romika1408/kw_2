#ifndef DRONE_CONTROLLER_H
#define DRONE_CONTROLLER_H

#include "drone.h"

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVector3D>

#include <functional>

// Связующий класс между Drone (логика полёта) и интерфейсом
// (форма Qt Designer + 3D-сцена QML). Сам Drone ничего не знает о Qt:
// контроллер вызывает его методы, перехватывает сообщения,
// которые Drone печатает в std::cout, и сообщает интерфейсу об изменениях.
class DroneController : public QObject {
    Q_OBJECT
    // Свойства, доступные из QML: drone.position, drone.battery и т.д.
    Q_PROPERTY(int drone_id READ get_id NOTIFY stateChanged)
    Q_PROPERTY(QVector3D position READ get_position NOTIFY stateChanged)
    Q_PROPERTY(double battery READ get_battery NOTIFY stateChanged)
    Q_PROPERTY(bool flying READ is_flying NOTIFY stateChanged)
    Q_PROPERTY(QVariantList path READ get_path NOTIFY pathChanged)

public:
    explicit DroneController(QObject* parent = nullptr);

    int get_id() const;
    QVector3D get_position() const;
    double get_battery() const;
    bool is_flying() const;
    QVariantList get_path() const;

public slots:
    void create_drone(int drone_id, double initial_battery);
    void takeoff();
    void land();
    void move_to(double new_x, double new_y, double new_z);
    void emergency_land();
    void set_battery(double value);

signals:
    void stateChanged();
    void pathChanged();
    void emergencyLanding();
    // kind: "ok" — успешное действие, "error" — отказ, "warning" — авария
    void logMessage(const QString& text, const QString& kind);

private:
    void run(const std::function<void()>& action);
    void update_path();

    Drone drone;
    QVariantList flight_path;
};

#endif
