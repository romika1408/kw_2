#ifndef DRONE_H
#define DRONE_H

// Класс Drone описывает состояние беспилотного летательного аппарата:
// идентификатор, координаты, заряд батареи и состояние полёта.
class Drone {
private:
    int id;
    double x;
    double y;
    double z;
    double battery;
    bool flying;

public:
    Drone();
    Drone(int drone_id, double initial_battery);

    void set_position(double new_x,
                      double new_y,
                      double new_z);
    void takeoff();
    void land();
    void move_to(double new_x,
                 double new_y,
                 double new_z);

    // Вариант 1: аварийная посадка
    void emergency_land();

    void set_battery(double value);
    int get_id() const;
    double get_x() const;
    double get_y() const;
    double get_z() const;
    double get_battery() const;
    bool is_flying() const;
    void print_info() const;
};

#endif
