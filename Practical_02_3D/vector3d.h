#ifndef VECTOR3D_H
#define VECTOR3D_H

#include <iostream>

// Трёхмерный вектор: координаты, скорость, ускорение,
// ветровая нагрузка, смещение относительно маршрута.
class Vector3D {
private:
    double x;
    double y;
    double z;

public:
    Vector3D();
    Vector3D(double x_value,
             double y_value,
             double z_value);

    double get_x() const;
    double get_y() const;
    double get_z() const;

    double length() const;
    void print() const;

    Vector3D operator+(
        const Vector3D& other
    ) const;

    Vector3D operator-(
        const Vector3D& other
    ) const;

    Vector3D operator*(
        double factor
    ) const;

    bool operator==(
        const Vector3D& other
    ) const;

    friend std::ostream& operator<<(
        std::ostream& output,
        const Vector3D& vector
    );
};

#endif
