#include "vector3d.h"

#include <iostream>
#include <iomanip>

// Вариант 1 задания 1: скорость БПЛА с учётом ветра
void run_velocity_task() {
    std::cout << "=== Variant 1: drone velocity ===\n";

    Vector3D drone_velocity(10.0, 4.0, -1.0);
    Vector3D wind_velocity(2.0, -1.0, 0.0);

    // Скорость относительно земли = воздушная скорость + скорость ветра
    Vector3D ground_velocity =
        drone_velocity + wind_velocity;

    std::cout << "Air velocity: "
              << drone_velocity << " m/s\n";
    std::cout << "Wind velocity: "
              << wind_velocity << " m/s\n";
    std::cout << "Ground velocity: "
              << ground_velocity << " m/s\n";
    std::cout << "Ground speed (length): "
              << ground_velocity.length() << " m/s\n";

    // Управляющее воздействие автопилота: 80% от скорости относительно земли
    Vector3D correction =
        ground_velocity * 0.8;

    std::cout << "Autopilot correction: "
              << correction << '\n';
    std::cout << "Correction length: "
              << correction.length() << '\n';
}

// Вариант 2 задания 1: перемещение по маршруту
void run_displacement_task() {
    std::cout << "\n=== Variant 2: route displacement ===\n";

    Vector3D start(0.0, 0.0, 100.0);
    Vector3D finish(300.0, 200.0, 150.0);

    // Вектор перемещения = конечная точка - начальная точка
    Vector3D displacement = finish - start;

    std::cout << "Start: " << start << '\n';
    std::cout << "Finish: " << finish << '\n';
    std::cout << "Displacement: " << displacement << '\n';
    std::cout << "Delta X: " << displacement.get_x() << " m\n";
    std::cout << "Delta Y: " << displacement.get_y() << " m\n";
    std::cout << "Delta altitude: " << displacement.get_z() << " m\n";
    std::cout << "Spatial distance: "
              << displacement.length() << " m\n";

    // Проверка: старт + перемещение должно дать конечную точку
    Vector3D check = start + displacement;
    bool result = (check == finish);

    std::cout << "Check (start + displacement): " << check << '\n';
    std::cout << "Check result: "
              << (result ? "OK, finish reached" : "ERROR") << '\n';
}

int main() {
    std::cout << std::fixed << std::setprecision(2);

    run_velocity_task();
    run_displacement_task();

    return 0;
}
