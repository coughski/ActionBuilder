//
//  ActionBuilder.swift
//  PetProject
//
//  Created by Kuba Szulaczkowski on 4/13/22.
//  Copyright © 2022 Kuba Szulaczkowski. All rights reserved.
//

import SpriteKit

public protocol Runnable {
    var action: SKAction { get }
}

public extension Runnable {
    static prefix func - (runnable: Self) -> SKAction {
        runnable.reversed()
    }
    
    static func * (left: Self, right: Int) -> Repeat {
        Repeat(.count(right), builtAction: { left })
    }
    
    static func * (left: Int, right: Self) -> Repeat {
        right * left
    }
    
    static func + (left: Runnable, right: Self) -> Sequence {
        Sequence {
            left
            right
        }
    }
    
    static func + (left: Self, right: Runnable) -> Sequence {
        right + left
    }
    
    static func & (left: Self, right: Runnable) -> Group {
        Group {
            left
            right
        }
    }
    
    static func & (left: Runnable, right: Self) -> Group {
        right & left
    }
    
    func reversed() -> SKAction {
        action.reversed()
    }
    
    func timingMode(_ mode: SKActionTimingMode) -> SKAction {
        let modifiedAction = action.copy() as! SKAction
        modifiedAction.timingMode = mode
        return modifiedAction
    }
    
    func duration(_ duration: TimeInterval) -> SKAction {
        let modifiedAction = action.copy() as! SKAction
        modifiedAction.duration = duration
        return modifiedAction
    }
    
    func speed(_ factor: Double) -> SKAction {
        let modifiedAction = action.copy() as! SKAction
        modifiedAction.speed = factor
        return modifiedAction
    }
    
    func runOn(_ node: SKNode) -> Custom {
        Custom {
            node.run(action)
        }
    }
}

@resultBuilder
public struct ActionBuilder {
    public static func buildExpression(_ expression: Runnable) -> [Runnable] {
        [expression]
    }
    
    public static func buildBlock(_ components: [Runnable]...) -> [Runnable] {
        return Array(components.joined())
    }
    
    public static func buildOptional(_ component: [Runnable]?) -> [Runnable] {
        guard let component = component else {
            return []
        }
        return component
    }
}

public protocol RunnableCollection: Runnable {
    var actions: [SKAction] { get }
    
    init(@ActionBuilder animation: () -> [Runnable])
    
    init(actions: [SKAction])
}

public extension RunnableCollection {
    init(@ActionBuilder animation: () -> [Runnable]) {
        self.init(actions: animation().map({ $0.action }))
    }
}

public extension SKNode {
    func run(_ action: Runnable, withKey key: String? = nil, completion block: (() -> Void)? = nil) {
        if let key = key {
            if let block = block {
                run((action + Custom(block: block)).action, withKey: key)
            } else {
                run(action.action, withKey: key)
            }
        } else {
            if let block = block {
                run((action + Custom(block: block)).action)
            } else {
                run(action.action)
            }
        }
    }
}

extension SKAction: Runnable {
    public var action: SKAction { self }
}

public struct Sequence: RunnableCollection {
    public private(set) var actions: [SKAction]
    
    public var action: SKAction {
        SKAction.sequence(actions)
    }
    
    public init(actions: [SKAction]) {
        self.actions = actions
    }
}

public struct Group: RunnableCollection {
    public private(set) var actions: [SKAction]
    
    public var action: SKAction {
        SKAction.group(actions)
    }
    
    public init(actions: [SKAction]) {
        self.actions = actions
    }
}

public struct Repeat: Runnable {
    public let action: SKAction
    let repetitions: Repetitions
    
    public enum Repetitions {
        case count(Int)
        case infinite
    }
    
    public init(_ repetitions: Repetitions, @ActionBuilder builtAction: () -> [Runnable]) {
        self.repetitions = repetitions
        let repeatAction = Sequence(animation: builtAction).action
        
        switch repetitions {
            case let .count(count):
                action = SKAction.repeat(repeatAction, count: count)
            case .infinite:
                action = SKAction.repeatForever(repeatAction)
        }
    }
}

public struct Wait: Runnable {
    public let action: SKAction
    
    public init(_ duration: TimeInterval = 1) {
        action = SKAction.wait(forDuration: duration)
    }
}

public struct Move: Runnable {
    public let action: SKAction
    
    public init(to point: (x: Double, y: Double) = (0, 0), duration: TimeInterval = 1) {
        action = SKAction.move(to: CGPoint(x: point.x, y: point.y), duration: duration)
    }
    
    public init(by delta: (x: Double, y: Double), duration: TimeInterval = 1) {
        action = SKAction.move(by: CGVector(dx: delta.x, dy: delta.y), duration: duration)
    }
    
    public init(by vector: CGVector, duration: TimeInterval = 1) {
        action = SKAction.move(by: vector, duration: duration)
    }
}

public struct Rotate: Runnable {
    public var action: SKAction
    
    public init(by angleRadians: Double, duration: TimeInterval = 1) {
        action = SKAction.rotate(byAngle: angleRadians, duration: duration)
    }
}

public struct Scale: Runnable {
    public let action: SKAction
    
    public init(to factor: Double = 1, duration: TimeInterval) {
        action = SKAction.scale(to: factor, duration: duration)
    }
    
    public init(by scale: Double, duration: TimeInterval) {
        action = SKAction.scale(by: scale, duration: duration)
    }
}

public struct FadeIn: Runnable {
    public let action: SKAction
    
    public init(_ duration: TimeInterval = 1) {
        action = SKAction.fadeIn(withDuration: duration)
    }
}

public struct FadeOut: Runnable {
    public let action: SKAction
    
    public init(_ duration: TimeInterval = 1) {
        action = SKAction.fadeOut(withDuration: duration)
    }
}

// animate, texture, colorize, fade

public struct Hide: Runnable {
    public var action: SKAction {
        SKAction.hide()
    }
    
    public init() {}
}

// these could be written as global functions instead, but with parentheses and lowercased
public struct Unhide: Runnable {
    public var action: SKAction {
        SKAction.unhide()
    }
    
    public init() {}
}

public struct PlaySound: Runnable {
    public let action: SKAction
    
    public init(_ file: String, waitForCompletion: Bool = false) {
        action = SKAction.playSoundFileNamed(file, waitForCompletion: waitForCompletion)
    }
}

public struct Remove: Runnable {
    public let action = SKAction.removeFromParent()
    
    public init() {}
}

public struct Custom: Runnable {
    public let action: SKAction
    
    public init(duration: TimeInterval = .zero, block: @escaping (_ targetNode: SKNode, _ elapsedTime: CGFloat) -> Void) {
        action = SKAction.customAction(withDuration: duration, actionBlock: block)
    }
    
    public init(block: @escaping () -> Void) {
        action = SKAction.run(block)
    }
}
