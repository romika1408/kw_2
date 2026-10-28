#include "drone_controller.h"

#include <iostream>
#include <sstream>

DroneController::DroneController(QObject* parent)
    : QObject(parent),
      drone(1, 100.0) {
    update_path();
}

int DroneController::get_id() const {
    return drone.get_id();
}

QVector3D DroneController::get_position() const {
    return QVector3D(drone.get_x(), drone.get_y(), drone.get_z());
}

double DroneController::get_battery() const {
    return drone.get_battery();
}

bool DroneController::is_flying() const {
    return drone.is_flying();
}

QVariantList DroneController::get_path() const {
    return flight_path;
}

void DroneController::create_drone(int drone_id, double initial_battery) {
    // Новый объект создаётся конструктором с параметрами,
    // проверка заряда (0-100 %) выполняется внутри Drone.
    drone = Drone(drone_id, initial_battery);
    flight_path.clear();
    emit logMessage(QString("Created drone #%1, battery %2 %")
                        .arg(drone_id)
                        .arg(drone.get_battery(), 0, 'f', 1),
                    "ok");
    run([] {});
}

void DroneController::takeoff() {
    run([this] { drone.takeoff(); });
}

void DroneController::land() {
    run([this] { drone.land(); });
}

void DroneController::move_to(double new_x, double new_y, double new_z) {
    run([this, new_x, new_y, new_z] { drone.move_to(new_x, new_y, new_z); });
}

void DroneController::emergency_land() {
    // Сигнал отправляется до изменения состояния,
    // чтобы 3D-сцена успела включить режим быстрого падения.
    emit emergencyLanding();
    run([this] { drone.emergency_land(); });
}

void DroneController::set_battery(double value) {
    run([this, value] { drone.set_battery(value); });
    emit logMessage(QString("Battery set to %1 %")
                        .arg(drone.get_battery(), 0, 'f', 1),
                    "ok");
}

// Выполняет действие над Drone и перехватывает всё, что он печатает:
// std::cout временно перенаправляется в строковый буфер.
// Каждая строка уходит в журнал интерфейса.
void DroneController::run(const std::function<void()>& action) {
    std::ostringstream buffer;
    std::streambuf* old_buffer = std::cout.rdbuf(buffer.rdbuf());
    action();
    std::cout.rdbuf(old_buffer);

    std::istringstream lines(buffer.str());
    std::string line;
    while (std::getline(lines, line)) {
        const QString text = QString::fromStdString(line);
        QString kind = "ok";
        if (text.contains("WARNING")) {
            kind = "warning";
        } else if (text.contains("denied") ||
                   text.contains("Error") ||
                   text.contains("already")) {
            kind = "error";
        }
        emit logMessage(text, kind);
    }

    update_path();
    emit stateChanged();
}

// Добавляет текущую точку в траекторию, если дрон сместился.
void DroneController::update_path() {
    const QVector3D current = get_position();
    if (!flight_path.isEmpty() &&
        flight_path.last().value<QVector3D>() == current) {
        return;
    }
    flight_path.append(QVariant::fromValue(current));
    emit pathChanged();
}
