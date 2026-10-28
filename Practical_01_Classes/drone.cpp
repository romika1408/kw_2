#include "drone.h"

#include <iostream>
#include <iomanip>

// Конструктор по умолчанию: аппарат в точке (0, 0, 0),
// батарея заряжена полностью, аппарат на земле.
Drone::Drone()
    : id(0),
      x(0.0),
      y(0.0),
      z(0.0),
      battery(100.0),
      flying(false) {
}

// Конструктор с параметрами. Заряд ограничивается диапазоном 0-100%.
Drone::Drone(int drone_id,
             double initial_battery)
    : id(drone_id),
      x(0.0),
      y(0.0),
      z(0.0),
      battery(0.0),
      flying(false) {
    set_battery(initial_battery);
}

void Drone::set_position(double new_x,
                         double new_y,
                         double new_z) {
    if (new_z < 0.0) {
        std::cout << "Error: altitude cannot be negative\n";
        return;
    }
    x = new_x;
    y = new_y;
    z = new_z;
}

// Взлёт: проверяем заряд и текущее состояние,
// затем поднимаем аппарат на 1 м и списываем 1% заряда.
void Drone::takeoff() {
    if (battery < 10.0) {
        std::cout << "Takeoff denied: low battery\n";
        return;
    }
    if (flying) {
        std::cout << "Drone is already flying\n";
        return;
    }
    flying = true;
    z = 1.0;
    battery -= 1.0;
    std::cout << "Drone took off\n";
}

void Drone::land() {
    if (!flying) {
        std::cout << "Drone is already on the ground\n";
        return;
    }
    flying = false;
    z = 0.0;
    std::cout << "Drone landed\n";
}

// Перемещение возможно только в полёте, на неотрицательную высоту
// и при заряде не ниже 5%. Каждое перемещение расходует 1% заряда.
void Drone::move_to(double new_x,
                    double new_y,
                    double new_z) {
    if (!flying) {
        std::cout << "Move denied: drone is not flying\n";
        return;
    }
    if (new_z < 0.0) {
        std::cout << "Move denied: invalid altitude\n";
        return;
    }
    if (battery < 5.0) {
        std::cout << "Move denied: critically low battery\n";
        return;
    }
    x = new_x;
    y = new_y;
    z = new_z;
    battery -= 1.0;
    std::cout << "Drone moved to new position\n";
}

// Аварийная посадка выполняется без проверок заряда и высоты:
// высота сразу обнуляется, состояние полёта отключается.
void Drone::emergency_land() {
    std::cout << "WARNING: Emergency landing activated\n";
    z = 0.0;
    flying = false;
    std::cout << "Drone landed immediately\n";
}

void Drone::set_battery(double value) {
    if (value < 0.0) {
        battery = 0.0;
    } else if (value > 100.0) {
        battery = 100.0;
    } else {
        battery = value;
    }
}

int Drone::get_id() const {
    return id;
}

double Drone::get_battery() const {
    return battery;
}

bool Drone::is_flying() const {
    return flying;
}

void Drone::print_info() const {
    std::cout << std::fixed
              << std::setprecision(2);

    std::cout << "Drone ID: " << id << '\n';
    std::cout << "Position: ("
              << x << ", "
              << y << ", "
              << z << ")\n";
    std::cout << "Battery: "
              << battery << "%\n";
    std::cout << "Status: "
              << (flying ? "Flying" : "On ground")
              << "\n";
}
