#include "drone.h"

#include <iostream>

// Практическое занятие №1, задание 1, вариант 1: управление полётом
int main() {
    Drone drone_1;
    drone_1.print_info();

    std::cout << "\n--- Takeoff ---\n";
    drone_1.takeoff();
    drone_1.print_info();

    std::cout << "\n--- Move ---\n";
    drone_1.move_to(10.0, 20.0, 50.0);
    drone_1.print_info();

    std::cout << "\n--- Landing ---\n";
    drone_1.land();
    drone_1.print_info();

    std::cout << "\n--- Check: low battery takeoff ---\n";
    Drone low_battery_drone(2, 5.0);
    low_battery_drone.takeoff();

    std::cout << "\n--- Check: double takeoff ---\n";
    drone_1.takeoff();
    drone_1.takeoff();
    drone_1.land();

    std::cout << "\n--- Check: move before takeoff ---\n";
    Drone drone_2(3, 80.0);
    drone_2.move_to(1.0, 2.0, 10.0);

    std::cout << "\n--- Check: set_battery limits ---\n";
    Drone drone_3(4, 150.0);
    std::cout << "Battery after constructor (150): "
              << drone_3.get_battery() << "%\n";
    drone_3.set_battery(-20.0);
    std::cout << "Battery after set_battery(-20): "
              << drone_3.get_battery() << "%\n";
    drone_3.set_battery(64.5);
    std::cout << "Battery after set_battery(64.5): "
              << drone_3.get_battery() << "%\n";

    std::cout << "\n--- Emergency landing ---\n";
    Drone drone_4(5, 70.0);
    drone_4.takeoff();
    drone_4.move_to(100.0, 50.0, 120.0);
    drone_4.print_info();
    drone_4.emergency_land();
    drone_4.print_info();

    return 0;
}
