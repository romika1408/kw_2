cmake_minimum_required(VERSION 3.16)

project(Practical_01_Classes LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(Practical_01_Classes
    main.cpp
    drone.h
    drone.cpp
)

include(GNUInstallDirs)
install(TARGETS Practical_01_Classes
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
