#include "vector_controller.h"

#include <iomanip>
#include <sstream>

namespace {

Vector3D from_qt(const QVector3D& vector) {
    return Vector3D(vector.x(), vector.y(), vector.z());
}

QVector3D to_qt(const Vector3D& vector) {
    return QVector3D(vector.get_x(), vector.get_y(), vector.get_z());
}

}

VectorController::VectorController(QObject* parent)
    : QObject(parent),
      mode(0),
      correction_factor(0.8),
      check_ok(false) {
    // Исходные данные из вариантов 1 и 2
    set_wind_task(QVector3D(10.0, 4.0, -1.0), QVector3D(2.0, -1.0, 0.0), 0.8);
    set_route_task(QVector3D(0.0, 0.0, 100.0), QVector3D(300.0, 200.0, 150.0));
}

QString VectorController::to_text(const Vector3D& vector) {
    std::ostringstream output;
    output << std::fixed << std::setprecision(2) << vector;
    return QString::fromStdString(output.str());
}

int VectorController::get_mode() const {
    return mode;
}

QVector3D VectorController::get_drone_velocity() const {
    return to_qt(drone_velocity);
}

QVector3D VectorController::get_wind_velocity() const {
    return to_qt(wind_velocity);
}

QVector3D VectorController::get_ground_velocity() const {
    return to_qt(ground_velocity);
}

QVector3D VectorController::get_correction() const {
    return to_qt(correction);
}

double VectorController::get_correction_factor() const {
    return correction_factor;
}

QVector3D VectorController::get_start_point() const {
    return to_qt(start_point);
}

QVector3D VectorController::get_finish_point() const {
    return to_qt(finish_point);
}

QVector3D VectorController::get_displacement() const {
    return to_qt(displacement);
}

bool VectorController::is_check_ok() const {
    return check_ok;
}

const Vector3D& VectorController::ground() const {
    return ground_velocity;
}

const Vector3D& VectorController::autopilot_correction() const {
    return correction;
}

const Vector3D& VectorController::route_displacement() const {
    return displacement;
}

const Vector3D& VectorController::route_check() const {
    return check_point;
}

void VectorController::set_mode(int new_mode) {
    if (mode == new_mode) {
        return;
    }
    mode = new_mode;
    emit changed();
}

void VectorController::set_wind_task(const QVector3D& drone,
                                     const QVector3D& wind,
                                     double factor) {
    drone_velocity = from_qt(drone);
    wind_velocity = from_qt(wind);
    correction_factor = factor;

    // Скорость относительно земли = воздушная скорость + скорость ветра
    ground_velocity = drone_velocity + wind_velocity;
    // Управляющее воздействие автопилота
    correction = ground_velocity * correction_factor;

    emit changed();
}

void VectorController::set_route_task(const QVector3D& start,
                                      const QVector3D& finish) {
    start_point = from_qt(start);
    finish_point = from_qt(finish);

    // Вектор перемещения = финиш - старт
    displacement = finish_point - start_point;
    // Проверка: старт + перемещение должно совпасть с финишем
    check_point = start_point + displacement;
    check_ok = (check_point == finish_point);

    emit changed();
}

void VectorController::request_animation() {
    emit animationRequested();
}
