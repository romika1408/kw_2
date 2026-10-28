#include "vector3d.h"

#include <cmath>

namespace {

// Сравнение чисел с плавающей точкой с допуском:
// прямое сравнение через == ненадёжно из-за ошибок округления.
bool nearly_equal(double a, double b) {
    return std::abs(a - b) < 0.000001;
}

}

Vector3D::Vector3D()
    : x(0.0), y(0.0), z(0.0) {
}

Vector3D::Vector3D(double x_value,
                   double y_value,
                   double z_value)
    : x(x_value),
      y(y_value),
      z(z_value) {
}

double Vector3D::get_x() const {
    return x;
}

double Vector3D::get_y() const {
    return y;
}

double Vector3D::get_z() const {
    return z;
}

// Длина (модуль) вектора: sqrt(x^2 + y^2 + z^2)
double Vector3D::length() const {
    return std::sqrt(
        x * x +
        y * y +
        z * z
    );
}

void Vector3D::print() const {
    std::cout << *this << '\n';
}

Vector3D Vector3D::operator+(
    const Vector3D& other
) const {
    return Vector3D(
        x + other.x,
        y + other.y,
        z + other.z
    );
}

Vector3D Vector3D::operator-(
    const Vector3D& other
) const {
    return Vector3D(
        x - other.x,
        y - other.y,
        z - other.z
    );
}

Vector3D Vector3D::operator*(
    double factor
) const {
    return Vector3D(
        x * factor,
        y * factor,
        z * factor
    );
}

bool Vector3D::operator==(
    const Vector3D& other
) const {
    return nearly_equal(x, other.x) &&
           nearly_equal(y, other.y) &&
           nearly_equal(z, other.z);
}

std::ostream& operator<<(
    std::ostream& output,
    const Vector3D& vector
) {
    output << "("
           << vector.x << ", "
           << vector.y << ", "
           << vector.z << ")";
    return output;
}
