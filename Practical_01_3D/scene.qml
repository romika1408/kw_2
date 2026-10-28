import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

// 3D-сцена полёта. Объект "drone" (DroneController) передаётся из C++.
// Система координат дрона: X — восток, Y — север, Z — высота.
// В Qt Quick 3D ось Y направлена вверх, поэтому координаты пересчитываются.
Item {
    id: root

    readonly property real metersToScene: 5.0   // 1 м = 5 единиц сцены
    property bool emergency: false

    function toScene(p) {
        return Qt.vector3d(p.x * metersToScene, p.z * metersToScene, -p.y * metersToScene)
    }

    // Поворот, переводящий ось +Y модели в направление dir
    // (нужен, чтобы ориентировать цилиндры-отрезки траектории).
    function rotationFromUp(dir) {
        const len = dir.length()
        if (len < 0.0001)
            return Qt.quaternion(1, 0, 0, 0)
        const d = dir.times(1.0 / len)
        const dot = d.y
        if (dot > 0.9999)
            return Qt.quaternion(1, 0, 0, 0)
        if (dot < -0.9999)
            return Qt.quaternion(0, 1, 0, 0)
        const axis = Qt.vector3d(0, 1, 0).crossProduct(d).normalized()
        const half = Math.acos(dot) / 2
        const s = Math.sin(half)
        return Qt.quaternion(Math.cos(half), axis.x * s, axis.y * s, axis.z * s)
    }

    View3D {
        id: view
        anchors.fill: parent
        camera: camera

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Color
            clearColor: "#0b1320"
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        Node {
            id: cameraOrigin
            y: 110
            PerspectiveCamera {
                id: camera
                position: Qt.vector3d(0, 300, 600)
                eulerRotation.x: -26
                clipFar: 20000
            }
        }

        DirectionalLight {
            eulerRotation.x: -55
            eulerRotation.y: -35
            brightness: 1.3
            castsShadow: true
            shadowFactor: 60
            shadowMapQuality: Light.ShadowMapQualityHigh
            ambientColor: "#3a4656"
        }

        // ---------- Земля ----------
        Model {
            source: "#Rectangle"
            eulerRotation.x: -90
            scale: Qt.vector3d(12, 12, 1)
            materials: PrincipledMaterial {
                baseColor: "#15261c"
                roughness: 0.95
            }
        }
        Model {
            y: 0.3
            eulerRotation.x: -90
            geometry: GridGeometry {
                horizontalLines: 25
                verticalLines: 25
                horizontalStep: 50
                verticalStep: 50
            }
            materials: PrincipledMaterial {
                lighting: PrincipledMaterial.NoLighting
                baseColor: "#2c4a37"
            }
        }

        // Посадочная площадка в точке (0, 0)
        Model {
            source: "#Cylinder"
            y: 0.5
            scale: Qt.vector3d(0.7, 0.01, 0.7)
            materials: PrincipledMaterial { baseColor: "#2d333b"; roughness: 0.8 }
        }
        Model {
            source: "#Cylinder"
            y: 0.9
            scale: Qt.vector3d(0.62, 0.005, 0.62)
            materials: PrincipledMaterial {
                lighting: PrincipledMaterial.NoLighting
                baseColor: "#d29922"
            }
        }
        Model {
            source: "#Cylinder"
            y: 1.2
            scale: Qt.vector3d(0.56, 0.005, 0.56)
            materials: PrincipledMaterial { baseColor: "#2d333b"; roughness: 0.8 }
        }

        // ---------- Траектория полёта ----------
        Repeater3D {
            model: drone.path
            delegate: Model {
                required property var modelData
                source: "#Sphere"
                position: root.toScene(modelData)
                scale: Qt.vector3d(0.05, 0.05, 0.05)
                materials: PrincipledMaterial {
                    lighting: PrincipledMaterial.NoLighting
                    baseColor: "#39c5cf"
                }
            }
        }
        Repeater3D {
            model: Math.max(0, drone.path.length - 1)
            delegate: Model {
                required property int index
                readonly property vector3d a: root.toScene(drone.path[index])
                readonly property vector3d b: root.toScene(drone.path[index + 1])
                source: "#Cylinder"
                position: a.plus(b).times(0.5)
                rotation: root.rotationFromUp(b.minus(a))
                scale: Qt.vector3d(0.012, b.minus(a).length() / 100, 0.012)
                materials: PrincipledMaterial {
                    lighting: PrincipledMaterial.NoLighting
                    baseColor: "#39c5cf"
                    opacity: 0.7
                }
            }
        }

        // Вертикальная линия от дрона к земле и метка под ним
        Model {
            source: "#Cylinder"
            visible: droneNode.y > 2
            position: Qt.vector3d(droneNode.x, droneNode.y / 2, droneNode.z)
            scale: Qt.vector3d(0.006, droneNode.y / 100, 0.006)
            materials: PrincipledMaterial {
                lighting: PrincipledMaterial.NoLighting
                baseColor: "#8b949e"
                opacity: 0.5
            }
        }
        Model {
            source: "#Cylinder"
            position: Qt.vector3d(droneNode.x, 1.5, droneNode.z)
            scale: Qt.vector3d(0.3, 0.002, 0.3)
            materials: PrincipledMaterial {
                lighting: PrincipledMaterial.NoLighting
                baseColor: root.emergency ? "#f85149" : "#58a6ff"
                opacity: 0.45
            }
        }

        // ---------- Модель дрона ----------
        Node {
            id: droneNode
            position: root.toScene(drone.position)

            // Обычный полёт — плавно, аварийная посадка — быстрое падение
            Behavior on position {
                Vector3dAnimation {
                    duration: root.emergency ? 700 : 1600
                    easing.type: root.emergency ? Easing.InQuad : Easing.InOutCubic
                }
            }

            Node {
                id: droneBody
                y: 6
                scale: Qt.vector3d(1.6, 1.6, 1.6)

                // Покачивание в полёте
                SequentialAnimation on eulerRotation.z {
                    running: drone.flying
                    loops: Animation.Infinite
                    NumberAnimation { from: -3; to: 3; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 3; to: -3; duration: 900; easing.type: Easing.InOutSine }
                }

                // Корпус
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(0.26, 0.08, 0.26)
                    materials: PrincipledMaterial {
                        baseColor: "#e6edf3"
                        metalness: 0.3
                        roughness: 0.35
                    }
                }
                Model {
                    source: "#Sphere"
                    y: 5
                    scale: Qt.vector3d(0.16, 0.06, 0.16)
                    materials: PrincipledMaterial { baseColor: "#1f6feb"; roughness: 0.2 }
                }
                // Камера-подвес
                Model {
                    source: "#Sphere"
                    position: Qt.vector3d(0, -6, -9)
                    scale: Qt.vector3d(0.07, 0.07, 0.07)
                    materials: PrincipledMaterial { baseColor: "#161b22"; roughness: 0.3 }
                }
                // Лучи рамы
                Model {
                    source: "#Cube"
                    eulerRotation.y: 45
                    scale: Qt.vector3d(0.95, 0.03, 0.05)
                    materials: PrincipledMaterial { baseColor: "#30363d"; roughness: 0.6 }
                }
                Model {
                    source: "#Cube"
                    eulerRotation.y: -45
                    scale: Qt.vector3d(0.95, 0.03, 0.05)
                    materials: PrincipledMaterial { baseColor: "#30363d"; roughness: 0.6 }
                }

                // Четыре мотора с винтами
                Repeater3D {
                    model: [Qt.vector3d(33, 0, 33), Qt.vector3d(-33, 0, 33),
                            Qt.vector3d(33, 0, -33), Qt.vector3d(-33, 0, -33)]
                    delegate: Node {
                        required property var modelData
                        required property int index
                        position: modelData

                        Model {
                            source: "#Cylinder"
                            y: 3
                            scale: Qt.vector3d(0.06, 0.08, 0.06)
                            materials: PrincipledMaterial { baseColor: "#161b22"; metalness: 0.6 }
                        }
                        Node {
                            y: 8
                            NumberAnimation on eulerRotation.y {
                                running: drone.flying
                                loops: Animation.Infinite
                                from: index % 2 === 0 ? 0 : 360
                                to: index % 2 === 0 ? 360 : 0
                                duration: 180
                            }
                            Model {
                                source: "#Cube"
                                scale: Qt.vector3d(0.34, 0.006, 0.04)
                                materials: PrincipledMaterial { baseColor: "#8b949e"; roughness: 0.4 }
                            }
                            // Диск вращения, заметный в полёте
                            Model {
                                source: "#Cylinder"
                                visible: drone.flying
                                scale: Qt.vector3d(0.17, 0.002, 0.17)
                                materials: PrincipledMaterial {
                                    lighting: PrincipledMaterial.NoLighting
                                    baseColor: "#c9d1d9"
                                    opacity: 0.18
                                }
                            }
                        }
                        // Навигационные огни: спереди зелёные, сзади красные
                        Model {
                            source: "#Sphere"
                            y: -3
                            scale: Qt.vector3d(0.03, 0.03, 0.03)
                            materials: PrincipledMaterial {
                                lighting: PrincipledMaterial.NoLighting
                                baseColor: root.emergency ? "#ff3b30"
                                         : !drone.flying ? "#484f58"
                                         : modelData.z < 0 ? "#3fb950" : "#f85149"
                            }
                        }
                    }
                }
            }
        }
    }

    // Вращение камеры мышью: ЛКМ — поворот, колесо — масштаб
    OrbitCameraController {
        anchors.fill: parent
        origin: cameraOrigin
        camera: camera
    }

    // Подпись над дроном (2D-метка, привязанная к 3D-точке)
    Item {
        id: droneLabel
        property int tick: 0
        readonly property vector3d screen: {
            tick
            if (!view.camera)
                return Qt.vector3d(0, 0, -1)
            return view.mapFrom3DScene(droneNode.position.plus(Qt.vector3d(0, 32, 0)))
        }
        x: screen.x - width / 2
        y: screen.y - height
        width: labelText.implicitWidth + 16
        height: labelText.implicitHeight + 8
        visible: screen.z > 0

        FrameAnimation {
            running: true
            onTriggered: droneLabel.tick++
        }
        Rectangle {
            anchors.fill: parent
            radius: 5
            color: "#cc0d1117"
            border.color: root.emergency ? "#f85149" : "#58a6ff"
        }
        Text {
            id: labelText
            anchors.centerIn: parent
            color: "#e6edf3"
            font.pixelSize: 12
            font.bold: true
            text: "DRONE #" + drone.drone_id + "  " + drone.position.z.toFixed(1) + " m"
        }
    }

    // ---------- HUD ----------
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 14
        width: 230
        height: hud.implicitHeight + 24
        radius: 10
        color: "#b30d1117"
        border.color: "#30363d"

        Column {
            id: hud
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Text {
                text: "ТЕЛЕМЕТРИЯ · DRONE #" + drone.drone_id
                color: "#58a6ff"
                font.pixelSize: 13
                font.bold: true
            }
            Text {
                color: "#e6edf3"
                font.pixelSize: 13
                font.family: "Consolas"
                text: "X   " + drone.position.x.toFixed(1) + " m\n"
                    + "Y   " + drone.position.y.toFixed(1) + " m\n"
                    + "ALT " + drone.position.z.toFixed(1) + " m"
            }
            // Индикатор заряда
            Rectangle {
                width: 206
                height: 18
                radius: 4
                color: "#21262d"
                Rectangle {
                    width: parent.width * drone.battery / 100
                    height: parent.height
                    radius: 4
                    color: drone.battery < 10 ? "#da3633"
                         : drone.battery < 20 ? "#d29922" : "#2ea043"
                    Behavior on width { NumberAnimation { duration: 400 } }
                }
                Text {
                    anchors.centerIn: parent
                    text: "BAT " + drone.battery.toFixed(1) + " %"
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.bold: true
                }
            }
            Text {
                text: drone.flying ? "● FLYING" : "● ON GROUND"
                color: drone.flying ? "#3fb950" : "#8b949e"
                font.pixelSize: 13
                font.bold: true
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 12
        text: "ЛКМ — вращать камеру · колесо — масштаб"
        color: "#6e7681"
        font.pixelSize: 11
    }

    // ---------- Аварийная индикация ----------
    Rectangle {
        id: alarmFrame
        anchors.fill: parent
        color: "transparent"
        border.color: "#f85149"
        border.width: 6
        opacity: 0
    }
    Rectangle {
        id: alarmBanner
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 18
        width: alarmText.implicitWidth + 40
        height: 44
        radius: 8
        color: "#da3633"
        opacity: 0
        Text {
            id: alarmText
            anchors.centerIn: parent
            text: "⚠ EMERGENCY LANDING"
            color: "white"
            font.pixelSize: 18
            font.bold: true
        }
    }

    SequentialAnimation {
        id: alarmAnimation
        ParallelAnimation {
            NumberAnimation { target: alarmBanner; property: "opacity"; to: 1; duration: 150 }
            SequentialAnimation {
                loops: 4
                NumberAnimation { target: alarmFrame; property: "opacity"; to: 1; duration: 250 }
                NumberAnimation { target: alarmFrame; property: "opacity"; to: 0.2; duration: 250 }
            }
        }
        PauseAnimation { duration: 600 }
        ParallelAnimation {
            NumberAnimation { target: alarmBanner; property: "opacity"; to: 0; duration: 500 }
            NumberAnimation { target: alarmFrame; property: "opacity"; to: 0; duration: 500 }
        }
        ScriptAction { script: root.emergency = false }
    }

    Connections {
        target: drone
        function onEmergencyLanding() {
            root.emergency = true
            alarmAnimation.restart()
        }
    }
}
