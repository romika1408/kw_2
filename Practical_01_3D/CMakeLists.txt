cmake_minimum_required(VERSION 3.16)

project(Practical_01_3D VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets Quick QuickWidgets Quick3D)

qt_standard_project_setup()

qt_add_executable(Practical_01_3D
    main.cpp
    mainwindow.h
    mainwindow.cpp
    mainwindow.ui
    drone.h
    drone.cpp
    drone_controller.h
    drone_controller.cpp
)

# 3D-сцена на QML хранится внутри программы как ресурс qrc:/scene.qml
qt_add_resources(Practical_01_3D "scene"
    PREFIX "/"
    FILES scene.qml
)

target_link_libraries(Practical_01_3D PRIVATE
    Qt6::Widgets
    Qt6::Quick
    Qt6::QuickWidgets
    Qt6::Quick3D
)

set_target_properties(Practical_01_3D PROPERTIES
    WIN32_EXECUTABLE ON
)
