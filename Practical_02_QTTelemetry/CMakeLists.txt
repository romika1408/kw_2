cmake_minimum_required(VERSION 3.16)

project(Practical_02_QTTelemetry LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(Practical_02_QTTelemetry
    main.cpp
    vector3d.h
    vector3d.cpp
)

include(GNUInstallDirs)
install(TARGETS Practical_02_QTTelemetry
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
