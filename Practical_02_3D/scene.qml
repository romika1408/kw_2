import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

// 3D-сцена векторов. Объект "calc" (VectorController) передаётся из C++.
// Система координат задачи: X — восток, Y — север, Z — высота.
// В Qt Quick 3D вверх направлена ось Y, поэтому координаты пересчитываются.
Item {
    id: root

    // Масштаб: число единиц сцены на единицу вектора.
    // Подбирается так, чтобы самый длинный вектор занимал около 260 единиц.
    property real k: 260 / Math.max(0.001, maxExtent())
    Behavior on k { NumberAnimation { duration: 600; easing.type: Easing.InOutCubic } }

    // Прогресс построения стрелок (0..1) для пошаговой анимации
    property real step1: 1
    property real step2: 1
    property real step3: 1
    property real step4: 1
    property int labelTick: 0

    readonly property int mode: calc.mode
    onModeChanged: buildAnimation.restart()

    // В варианте 1 векторы скорости откладываются от дрона, висящего
    // в воздухе (точка anchor), в варианте 2 — от начала координат.
    readonly property vector3d anchor: calc.mode === 0 ? Qt.vector3d(0, 120, 0) : Qt.vector3d(0, 0, 0)

    function toScene(v) {
        return Qt.vector3d(anchor.x + v.x * k, anchor.y + v.z * k, anchor.z - v.y * k)
    }

    function fmt(v) {
        return "(" + v.x.toFixed(2) + ", " + v.y.toFixed(2) + ", " + v.z.toFixed(2) + ")"
    }

    function maxExtent() {
        if (calc.mode === 0) {
            const tip = calc.drone_velocity.plus(calc.wind_velocity)
            return Math.max(calc.drone_velocity.length(), tip.length(), calc.correction.length())
        }
        return Math.max(calc.start_point.length(), calc.finish_point.length())
    }

    // ---------- Стрелка-вектор от точки from до точки to ----------
    component Arrow: Node {
        id: arrow
        property vector3d from: Qt.vector3d(0, 0, 0)
        property vector3d to: Qt.vector3d(0, 0, 0)
        property color color: "white"
        property real thickness: 1.0
        property real progress: 1.0
        property bool head: true

        readonly property vector3d direction: to.minus(from)
        readonly property real length: direction.length() * progress
        readonly property real headLength: head ? Math.min(length * 0.4, 20 * thickness) : 0
        readonly property real shaftLength: Math.max(0, length - headLength)

        // Поворот, переводящий ось +Y модели в направление вектора
        function rotationFromUp(dir) {
            const len = dir.length()
            if (len < 0.0001)
                return Qt.quaternion(1, 0, 0, 0)
            const d = dir.times(1.0 / len)
            if (d.y > 0.9999)
                return Qt.quaternion(1, 0, 0, 0)
            if (d.y < -0.9999)
                return Qt.quaternion(0, 1, 0, 0)
            const axis = Qt.vector3d(0, 1, 0).crossProduct(d).normalized()
            const half = Math.acos(d.y) / 2
            const s = Math.sin(half)
            return Qt.quaternion(Math.cos(half), axis.x * s, axis.y * s, axis.z * s)
        }

        position: from
        rotation: rotationFromUp(direction)
        visible: length > 0.5

        Model {
            source: "#Cylinder"
            y: arrow.shaftLength / 2
            scale: Qt.vector3d(0.055 * arrow.thickness, arrow.shaftLength / 100, 0.045 * arrow.thickness)
            materials: PrincipledMaterial { baseColor: arrow.color; roughness: 0.35; metalness: 0.1 }
        }
        Model {
            source: "#Cone"
            visible: arrow.head
            y: arrow.shaftLength
            scale: Qt.vector3d(0.13 * arrow.thickness, arrow.headLength / 100, 0.13 * arrow.thickness)
            materials: PrincipledMaterial { baseColor: arrow.color; roughness: 0.35; metalness: 0.1 }
        }
    }

    // Тонкая линия между двумя точками (вспомогательные построения)
    component Line: Arrow {
        thickness: 0.25
        head: false
    }

    // ---------- Подпись, привязанная к 3D-точке ----------
    component TipLabel: Rectangle {
        id: tip
        property View3D view3d
        property vector3d target
        property int tick
        property alias text: caption.text
        property color accent: "white"
        property real offsetY: 0

        readonly property vector3d screen: {
            tick
            if (!view3d || !view3d.camera)
                return Qt.vector3d(0, 0, -1)
            return view3d.mapFrom3DScene(target)
        }
        x: screen.x + 10
        y: screen.y - height - 6 + offsetY
        width: caption.implicitWidth + 14
        height: caption.implicitHeight + 6
        radius: 5
        color: "#d90d1117"
        border.color: accent
        visible: screen.z > 0 && opacity > 0.01

        Text {
            id: caption
            anchors.centerIn: parent
            color: tip.accent
            font.pixelSize: 12
            font.bold: true
        }
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
            position: calc.mode === 0
                      ? root.toScene(calc.ground_velocity).times(0.5)
                      : root.toScene(calc.start_point.plus(calc.finish_point).times(0.5))
            eulerRotation.y: -12
            Behavior on position { Vector3dAnimation { duration: 600; easing.type: Easing.InOutCubic } }

            PerspectiveCamera {
                id: camera
                position: Qt.vector3d(0, 210, 470)
                eulerRotation.x: -24
                clipFar: 20000
            }
        }

        DirectionalLight {
            eulerRotation.x: -50
            eulerRotation.y: -30
            brightness: 1.2
            castsShadow: true
            shadowFactor: 40
            ambientColor: "#3a4656"
        }

        // ---------- Плоскость земли и сетка ----------
        Model {
            source: "#Rectangle"
            y: -0.5
            eulerRotation.x: -90
            scale: Qt.vector3d(9, 9, 1)
            materials: PrincipledMaterial { baseColor: "#111d2b"; roughness: 0.95 }
        }
        Model {
            eulerRotation.x: -90
            geometry: GridGeometry {
                horizontalLines: 37
                verticalLines: 37
                horizontalStep: 25
                verticalStep: 25
            }
            materials: PrincipledMaterial {
                lighting: PrincipledMaterial.NoLighting
                baseColor: "#1f3247"
            }
        }

        // ---------- Оси координат ----------
        Arrow { to: Qt.vector3d(330, 0, 0); color: "#8b3a3a"; thickness: 0.45 }
        Arrow { to: Qt.vector3d(0, 0, -330); color: "#2f6b3a"; thickness: 0.45 }
        Arrow { to: Qt.vector3d(0, 330, 0); color: "#2f4f8b"; thickness: 0.45 }
        Model {
            source: "#Sphere"
            scale: Qt.vector3d(0.06, 0.06, 0.06)
            materials: PrincipledMaterial { baseColor: "#e6edf3" }
        }

        // ---------- Вариант 1: скорость БПЛА и ветер ----------
        Node {
            visible: calc.mode === 0

            // Маркер дрона и его проекция на землю
            Model {
                source: "#Sphere"
                position: root.anchor
                scale: Qt.vector3d(0.14, 0.14, 0.14)
                materials: PrincipledMaterial { baseColor: "#e6edf3"; metalness: 0.4; roughness: 0.25 }
            }
            Line {
                from: root.anchor
                to: Qt.vector3d(0, 0, 0)
                color: "#6e7681"
            }

            // Воздушная скорость дрона
            Arrow {
                from: root.anchor
                to: root.toScene(calc.drone_velocity)
                color: "#58a6ff"
                progress: root.step1
            }
            // Ветер откладывается от конца вектора скорости (правило треугольника)
            Arrow {
                from: root.toScene(calc.drone_velocity)
                to: root.toScene(calc.drone_velocity.plus(calc.wind_velocity))
                color: "#f0883e"
                progress: root.step2
            }
            // Скорость относительно земли — сумма
            Arrow {
                from: root.anchor
                to: root.toScene(calc.ground_velocity)
                color: "#3fb950"
                thickness: 1.35
                progress: root.step3
            }
            // Поправка автопилота k · v
            Arrow {
                from: root.anchor
                to: root.toScene(calc.correction)
                color: "#bc8cff"
                thickness: 0.8
                progress: root.step4
            }
            // Проекция результата на землю
            Line {
                from: root.toScene(calc.ground_velocity)
                to: Qt.vector3d(root.toScene(calc.ground_velocity).x, 0, root.toScene(calc.ground_velocity).z)
                color: "#6e7681"
                opacity: root.step3
            }
        }

        // ---------- Вариант 2: перемещение по маршруту ----------
        Node {
            visible: calc.mode === 1

            readonly property vector3d start: root.toScene(calc.start_point)
            readonly property vector3d finish: root.toScene(calc.finish_point)
            readonly property vector3d afterX: root.toScene(calc.start_point.plus(Qt.vector3d(calc.displacement.x, 0, 0)))
            readonly property vector3d afterXY: root.toScene(calc.start_point.plus(Qt.vector3d(calc.displacement.x, calc.displacement.y, 0)))

            Model {
                source: "#Sphere"
                position: parent.start
                scale: Qt.vector3d(0.16, 0.16, 0.16)
                materials: PrincipledMaterial { baseColor: "#3fb950"; roughness: 0.3 }
            }
            Model {
                source: "#Sphere"
                position: parent.finish
                scale: Qt.vector3d(0.16, 0.16, 0.16)
                materials: PrincipledMaterial { baseColor: "#f85149"; roughness: 0.3 }
            }
            // Высота точек: вертикальные линии до земли
            Line {
                from: parent.start
                to: Qt.vector3d(parent.start.x, 0, parent.start.z)
                color: "#3fb950"
            }
            Line {
                from: parent.finish
                to: Qt.vector3d(parent.finish.x, 0, parent.finish.z)
                color: "#f85149"
            }
            // Составляющие перемещения: ΔX, ΔY, ΔZ
            Arrow {
                from: parent.start
                to: parent.afterX
                color: "#ff7b72"
                thickness: 0.7
                progress: root.step1
            }
            Arrow {
                from: parent.afterX
                to: parent.afterXY
                color: "#56d364"
                thickness: 0.7
                progress: root.step2
            }
            Arrow {
                from: parent.afterXY
                to: parent.finish
                color: "#79c0ff"
                thickness: 0.7
                progress: root.step3
            }
            // Полный вектор перемещения finish - start
            Arrow {
                from: parent.start
                to: parent.finish
                color: "#e3b341"
                thickness: 1.4
                progress: root.step4
            }
        }
    }

    OrbitCameraController {
        anchors.fill: parent
        origin: cameraOrigin
        camera: camera
    }

    FrameAnimation {
        running: true
        onTriggered: root.labelTick++
    }

    // ---------- Подписи осей и векторов ----------
    TipLabel { view3d: view; tick: root.labelTick; target: Qt.vector3d(330, 0, 0); text: "X (восток)"; accent: "#ff7b72" }
    TipLabel { view3d: view; tick: root.labelTick; target: Qt.vector3d(0, 0, -330); text: "Y (север)"; accent: "#56d364" }
    TipLabel { view3d: view; tick: root.labelTick; target: Qt.vector3d(0, 330, 0); text: "Z (высота)"; accent: "#79c0ff" }

    TipLabel {
        view3d: view; tick: root.labelTick
        visible: calc.mode === 0 && screen.z > 0
        opacity: root.step1
        target: root.toScene(calc.drone_velocity.times(0.45))
        text: "v дрона"
        accent: "#58a6ff"
    }
    TipLabel {
        view3d: view; tick: root.labelTick
        visible: calc.mode === 0 && screen.z > 0
        opacity: root.step2
        target: root.toScene(calc.drone_velocity.plus(calc.wind_velocity.times(0.5)))
        offsetY: -34
        text: "ветер"
        accent: "#f0883e"
    }
    TipLabel {
        view3d: view; tick: root.labelTick
        visible: calc.mode === 0 && screen.z > 0
        opacity: root.step3
        target: root.toScene(calc.ground_velocity)
        offsetY: 44
        text: "v земли = " + calc.ground_velocity.length().toFixed(2) + " м/с"
        accent: "#3fb950"
    }
    TipLabel {
        view3d: view; tick: root.labelTick
        visible: calc.mode === 0 && screen.z > 0
        opacity: root.step4
        target: root.toScene(calc.correction)
        text: "поправка k·v"
        accent: "#bc8cff"
    }

    TipLabel {
        view3d: view; tick: root.labelTick
        visible: calc.mode === 1 && screen.z > 0
        target: root.toScene(calc.start_point)
        text: "СТАРТ " + root.fmt(calc.start_point)
        accent: "#3fb950"
    }
    TipLabel {
        view3d: view; tick: root.labelTick
        visible: calc.mode === 1 && screen.z > 0
        target: root.toScene(calc.finish_point)
        text: "ФИНИШ " + root.fmt(calc.finish_point)
        accent: "#f85149"
    }
    TipLabel {
        view3d: view; tick: root.labelTick
        visible: calc.mode === 1 && screen.z > 0
        opacity: root.step4
        target: root.toScene(calc.start_point.plus(calc.displacement.times(0.5)))
        text: "Δ = " + calc.displacement.length().toFixed(2) + " м"
        accent: "#e3b341"
    }
    TipLabel {
        view3d: view; tick: root.labelTick
        visible: calc.mode === 1 && screen.z > 0
        opacity: root.step1
        target: root.toScene(calc.start_point.plus(Qt.vector3d(calc.displacement.x * 0.5, 0, 0)))
        text: "ΔX = " + calc.displacement.x.toFixed(1)
        accent: "#ff7b72"
    }
    TipLabel {
        view3d: view; tick: root.labelTick
        visible: calc.mode === 1 && screen.z > 0
        opacity: root.step2
        target: root.toScene(calc.start_point.plus(Qt.vector3d(calc.displacement.x, calc.displacement.y * 0.5, 0)))
        text: "ΔY = " + calc.displacement.y.toFixed(1)
        accent: "#56d364"
    }
    TipLabel {
        view3d: view; tick: root.labelTick
        visible: calc.mode === 1 && screen.z > 0
        opacity: root.step3
        target: root.toScene(calc.start_point.plus(Qt.vector3d(calc.displacement.x, calc.displacement.y, calc.displacement.z * 0.5)))
        text: "ΔZ = " + calc.displacement.z.toFixed(1)
        accent: "#79c0ff"
    }

    // ---------- Легенда ----------
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 14
        width: legend.implicitWidth + 28
        height: legend.implicitHeight + 24
        radius: 10
        color: "#b30d1117"
        border.color: "#30363d"

        Column {
            id: legend
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: calc.mode === 0 ? "ВАРИАНТ 1 · СКОРОСТЬ БПЛА" : "ВАРИАНТ 2 · ПЕРЕМЕЩЕНИЕ"
                color: "#e6edf3"
                font.pixelSize: 13
                font.bold: true
            }
            Repeater {
                model: calc.mode === 0
                       ? [{ c: "#58a6ff", t: "v дрона   " + root.fmt(calc.drone_velocity) },
                          { c: "#f0883e", t: "ветер     " + root.fmt(calc.wind_velocity) },
                          { c: "#3fb950", t: "v земли   " + root.fmt(calc.ground_velocity) },
                          { c: "#bc8cff", t: "k·v       " + root.fmt(calc.correction) + "  k=" + calc.correction_factor.toFixed(2) }]
                       : [{ c: "#3fb950", t: "старт     " + root.fmt(calc.start_point) },
                          { c: "#f85149", t: "финиш     " + root.fmt(calc.finish_point) },
                          { c: "#e3b341", t: "Δ         " + root.fmt(calc.displacement) },
                          { c: "#8b949e", t: "|Δ|       " + calc.displacement.length().toFixed(2) + " м" }]
                delegate: Row {
                    required property var modelData
                    spacing: 8
                    Rectangle {
                        width: 14
                        height: 14
                        radius: 3
                        color: modelData.c
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData.t
                        color: "#c9d1d9"
                        font.family: "Consolas"
                        font.pixelSize: 13
                    }
                }
            }
        }
    }

    // ---------- Спидометр (вариант 1) ----------
    Rectangle {
        visible: calc.mode === 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        width: 210
        height: 200
        radius: 10
        color: "#b30d1117"
        border.color: "#30363d"

        Canvas {
            id: gauge
            anchors.fill: parent
            property real value: calc.ground_velocity.length()
            property real maximum: Math.max(20, Math.ceil(value / 10) * 10)
            Behavior on value { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            onValueChanged: requestPaint()
            onMaximumChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const cx = width / 2
                const cy = height * 0.55
                const r = 70
                const startAngle = Math.PI * 0.75
                const endAngle = Math.PI * 2.25
                const angle = startAngle + (endAngle - startAngle) * Math.min(1, value / maximum)

                ctx.lineCap = "round"
                ctx.lineWidth = 12
                ctx.strokeStyle = "#21262d"
                ctx.beginPath()
                ctx.arc(cx, cy, r, startAngle, endAngle)
                ctx.stroke()

                const gradient = ctx.createLinearGradient(cx - r, 0, cx + r, 0)
                gradient.addColorStop(0, "#3fb950")
                gradient.addColorStop(1, "#58a6ff")
                ctx.strokeStyle = gradient
                ctx.beginPath()
                ctx.arc(cx, cy, r, startAngle, angle)
                ctx.stroke()

                ctx.lineWidth = 2
                ctx.strokeStyle = "#6e7681"
                for (let i = 0; i <= 10; ++i) {
                    const t = startAngle + (endAngle - startAngle) * i / 10
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(t) * (r - 14), cy + Math.sin(t) * (r - 14))
                    ctx.lineTo(cx + Math.cos(t) * (r - 22), cy + Math.sin(t) * (r - 22))
                    ctx.stroke()
                }

                ctx.lineWidth = 3
                ctx.strokeStyle = "#e6edf3"
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx + Math.cos(angle) * (r - 26), cy + Math.sin(angle) * (r - 26))
                ctx.stroke()
                ctx.fillStyle = "#e6edf3"
                ctx.beginPath()
                ctx.arc(cx, cy, 5, 0, Math.PI * 2)
                ctx.fill()
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
            text: "СКОРОСТЬ ОТН. ЗЕМЛИ"
            color: "#8b949e"
            font.pixelSize: 11
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            text: gauge.value.toFixed(2) + " м/с"
            color: "#3fb950"
            font.pixelSize: 20
            font.bold: true
        }
    }

    // ---------- Проверка (вариант 2) ----------
    Rectangle {
        visible: calc.mode === 1
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        width: checkText.implicitWidth + 28
        height: 46
        radius: 10
        color: calc.check_ok ? "#1a3d24" : "#4a1a1a"
        border.color: calc.check_ok ? "#3fb950" : "#f85149"
        Text {
            id: checkText
            anchors.centerIn: parent
            text: calc.check_ok ? "✔ старт + Δ == финиш" : "✘ проверка не пройдена"
            color: calc.check_ok ? "#3fb950" : "#f85149"
            font.pixelSize: 15
            font.bold: true
        }
    }

    // ---------- Формула ----------
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 34
        width: formula.implicitWidth + 30
        height: formula.implicitHeight + 14
        radius: 8
        color: "#b30d1117"
        border.color: "#30363d"
        Text {
            id: formula
            anchors.centerIn: parent
            color: "#e6edf3"
            font.family: "Consolas"
            font.pixelSize: 14
            text: calc.mode === 0
                  ? "ground_velocity = drone_velocity + wind_velocity      correction = ground_velocity * " + calc.correction_factor.toFixed(2)
                  : "displacement = finish - start      check = start + displacement"
        }
    }

    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        text: "ЛКМ — вращать камеру · колесо — масштаб"
        color: "#6e7681"
        font.pixelSize: 11
    }

    // ---------- Пошаговая анимация построения ----------
    SequentialAnimation {
        id: buildAnimation
        ScriptAction {
            script: {
                root.step1 = 0
                root.step2 = 0
                root.step3 = 0
                root.step4 = 0
            }
        }
        PauseAnimation { duration: 250 }
        NumberAnimation { target: root; property: "step1"; to: 1; duration: 900; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "step2"; to: 1; duration: 900; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "step3"; to: 1; duration: 900; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "step4"; to: 1; duration: 900; easing.type: Easing.OutCubic }
    }

    Connections {
        target: calc
        function onAnimationRequested() {
            buildAnimation.restart()
        }
    }
}
