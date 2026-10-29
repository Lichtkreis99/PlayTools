//
//  JoystickButton.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/12/25.
//

import Foundation

protocol ParentElement {
    func unfocusChildren()
    var button: Element { get }
}

class ChildButtonModel: ControlModel<Button> {
    var parent: ParentElement
    init(data: Button, parent: ParentElement) {
        self.parent = parent
        super.init(data: data)
        self.setKey(code: data.keyCode)
        parent.button.addSubview(button)
    }

    override func remove() {
        parent.button.removeFromSuperview()
    }

    override func setKey(code: Int, name: String) {
        var buttonData = data
        buttonData.keyCode = code
        buttonData.keyName = name
        data = buttonData
        button.setTitle(data.keyName, for: UIControl.State.normal)
    }

    override func move(deltaY: CGFloat, deltaX: CGFloat) {
        parent.button.model?.move(deltaY: deltaY, deltaX: deltaX)
    }

    override func resize(down: Bool) {
        parent.button.model?.resize(down: down)
    }

    override func focus(_ focus: Bool) {
        if focus {
            parent.unfocusChildren()
        }
        super.focus(focus)
    }
}

class SwipeGroupModel: ControlModel<SwipeGroup>, ParentElement {
    var swipeKeys = [SwipeKeyModel]()

    override init(data: SwipeGroup) {
        super.init(data: data)
        button.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.8)
        button.setTitle("Swipe", for: UIControl.State.normal)
        swipeKeys = data.keys.map { SwipeKeyModel(data: $0, parent: self) }
    }

    func save() -> SwipeGroup {
        data.keys = swipeKeys.map { $0.data }
        return data
    }

    func attachChildren(to view: UIView) {
        swipeKeys.forEach { $0.attach(to: view) }
    }

    func unfocusChildren() {
        swipeKeys.forEach { $0.focus(false) }
    }

    override func focus(_ focus: Bool) {
        super.focus(focus)
        if !focus {
            unfocusChildren()
        }
    }

    override func setKey(code: Int, name: String) {
        guard code >= 0 else {
            return
        }
        let angle = -CGFloat.pi / 2 + CGFloat(swipeKeys.count) * CGFloat.pi / 4
        let ring = swipeKeys.count / 8
        let distance = CGFloat(12 + ring * 7).absoluteSize
        let center = button.center
        let point = CGPoint(
            x: min(max(center.x + cos(angle) * distance, 0), screen.width),
            y: min(max(center.y + sin(angle) * distance, 0), screen.height))
        let key = SwipeKey(
            keyCode: code,
            keyName: name,
            transform: KeyModelTransform(
                size: 5,
                xCoord: point.x.relativeX,
                yCoord: point.y.relativeY))
        let model = SwipeKeyModel(data: key, parent: self)
        swipeKeys.append(model)
        data.keys.append(key)
        if let view = button.superview {
            model.attach(to: view)
        }
    }

    override func move(deltaY: CGFloat, deltaX: CGFloat) {
        let oldCenter = button.center
        var newCenter = oldCenter
        if oldCenter.x + deltaX > 0 && oldCenter.x + deltaX < screen.width {
            newCenter.x += deltaX
            data.transform.xCoord = newCenter.x.relativeX
        }
        if oldCenter.y + deltaY > 0 && oldCenter.y + deltaY < screen.height {
            newCenter.y += deltaY
            data.transform.yCoord = newCenter.y.relativeY
        }
        button.setCenterXY(newX: newCenter.x, newY: newCenter.y)
        let movedX = newCenter.x - oldCenter.x
        let movedY = newCenter.y - oldCenter.y
        swipeKeys.forEach { $0.moveWithParent(deltaY: movedY, deltaX: movedX) }
    }

    func removeChild(_ child: SwipeKeyModel) {
        swipeKeys.removeAll(where: { $0 === child })
        data.keys = swipeKeys.map { $0.data }
    }

    override func remove() {
        swipeKeys.forEach { $0.detach() }
        super.remove()
    }
}

class SwipeKeyModel: ControlModel<SwipeKey> {
    unowned let parent: SwipeGroupModel
    private let lineLayer = CAShapeLayer()

    init(data: SwipeKey, parent: SwipeGroupModel) {
        self.parent = parent
        super.init(data: data)
        button.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.8)
        setKey(code: data.keyCode, name: data.keyName)
        lineLayer.strokeColor = UIColor.systemTeal.withAlphaComponent(0.8).cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = 2
        lineLayer.lineDashPattern = [6, 4]
    }

    func attach(to view: UIView) {
        lineLayer.frame = view.bounds
        if lineLayer.superlayer == nil {
            view.layer.insertSublayer(lineLayer, at: 0)
        }
        if button.superview == nil {
            view.addSubview(button)
        }
        updateLine()
    }

    override func setKey(code: Int, name: String) {
        data.keyCode = code
        data.keyName = name
        button.setTitle(name, for: UIControl.State.normal)
    }

    override func move(deltaY: CGFloat, deltaX: CGFloat) {
        var newCenter = button.center
        if newCenter.x + deltaX > 0 && newCenter.x + deltaX < screen.width {
            newCenter.x += deltaX
            data.transform.xCoord = newCenter.x.relativeX
        }
        if newCenter.y + deltaY > 0 && newCenter.y + deltaY < screen.height {
            newCenter.y += deltaY
            data.transform.yCoord = newCenter.y.relativeY
        }
        button.setCenterXY(newX: newCenter.x, newY: newCenter.y)
        updateLine()
    }

    func moveWithParent(deltaY: CGFloat, deltaX: CGFloat) {
        let newX = button.center.x + deltaX
        let newY = button.center.y + deltaY
        data.transform.xCoord = newX.relativeX
        data.transform.yCoord = newY.relativeY
        button.setCenterXY(newX: newX, newY: newY)
        updateLine()
    }

    override func resize(down: Bool) {
        super.resize(down: down)
        updateLine()
    }

    override func focus(_ focus: Bool) {
        if focus {
            parent.unfocusChildren()
        }
        super.focus(focus)
    }

    override func remove() {
        parent.removeChild(self)
        detach()
    }

    func detach() {
        lineLayer.removeFromSuperlayer()
        button.removeFromSuperview()
    }

    private func updateLine() {
        let path = UIBezierPath()
        path.move(to: parent.button.center)
        path.addLine(to: button.center)
        lineLayer.path = path.cgPath
    }
}
