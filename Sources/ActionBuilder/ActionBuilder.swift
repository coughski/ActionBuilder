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
        Repeat(.count(right), runnable: { left })
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
    
    static func & (left: Self, right: Runnable) -> Group {
        Group {
            left
            right
        }
    }
}
 
public extension Runnable {
    func reversed() -> SKAction {
        action.reversed()
    }
    
    func changeTarget(to node: SKNode) -> Custom {
        Custom {
            node.run(action)
        }
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
}

@resultBuilder
public struct ActionBuilder {
    public static func buildBlock(_ components: [Runnable]...) -> [Runnable] {
        Array(components.joined())
    }
    
    public static func buildOptional(_ component: [Runnable]?) -> [Runnable] {
        guard let component = component else {
            return []
        }
        return component
    }
    
    public static func buildEither(first component: [Runnable]) -> [Runnable] {
        component
    }
    
    public static func buildEither(second component: [Runnable]) -> [Runnable] {
        component
    }
    
    public static func buildArray(_ components: [[Runnable]]) -> [Runnable] {
        Array(components.joined())
    }
    
    public static func buildExpression(_ expression: Runnable) -> [Runnable] {
        [expression]
    }
}

public protocol RunnableCollection: Runnable {
    var actions: [SKAction] { get }
    
    init(@ActionBuilder builtAction: () -> [Runnable])
    
    init(actions: [SKAction])
}

public extension RunnableCollection {
    init(@ActionBuilder builtAction: () -> [Runnable]) {
        self.init(actions: builtAction().map({ $0.action }))
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
    
    func run(withKey key: String? = nil, _ runnable: () -> Runnable, completion block: (() -> Void)? = nil) {
        run(runnable(), withKey: key, completion: block)
    }
}

extension SKAction: Runnable {
    public var action: SKAction { self }
}

public struct Sequence: RunnableCollection {
    public private(set) var actions: [SKAction]
    
    public var action: SKAction {
        .sequence(actions)
    }
    
    public init(actions: [SKAction]) {
        self.actions = actions
    }
}

public struct Group: RunnableCollection {
    public private(set) var actions: [SKAction]
    
    public var action: SKAction {
        .group(actions)
    }
    
    public init(actions: [SKAction]) {
        self.actions = actions
    }
}

public struct Repeat: Runnable {
    public let action: SKAction
    
    public enum Repetitions {
        case count(Int)
        case infinite
    }
    
    public init(_ repetitions: Repetitions, runnable: () -> Runnable) {
        let repeatAction = runnable().action
        
        switch repetitions {
            case let .count(count):
                action = .repeat(repeatAction, count: count)
            case .infinite:
                action = .repeatForever(repeatAction)
        }
    }
}

public struct Wait: Runnable {
    public let action: SKAction
    
    public init(_ duration: TimeInterval = 0.5) {
        action = .wait(forDuration: duration)
    }
}

public struct Move: Runnable {
    public let action: SKAction
    
    public init(to point: (x: Double, y: Double) = (0, 0), over interval: TimeInterval = 1) {
        action = .move(to: CGPoint(x: point.x, y: point.y), duration: interval)
    }
    
    public init(by delta: (x: Double, y: Double), over interval: TimeInterval = 1) {
        action = .move(by: CGVector(dx: delta.x, dy: delta.y), duration: interval)
    }
    
    public init(by vector: CGVector, over interval: TimeInterval = 1) {
        action = .move(by: vector, duration: interval)
    }
}

public struct Rotate: Runnable {
    public var action: SKAction
    
    public init(to angleRadians: Double, over interval: TimeInterval = 1) {
        action = .rotate(toAngle: angleRadians, duration: interval)
    }
    
    public init(by angleRadians: Double, over interval: TimeInterval = 1) {
        action = .rotate(byAngle: angleRadians, duration: interval)
    }
}

public struct Scale: Runnable {
    public let action: SKAction
    
    public init(to factor: Double = 1, over interval: TimeInterval) {
        action = .scale(to: factor, duration: interval)
    }
    
    public init(by scale: Double, over interval: TimeInterval) {
        action = .scale(by: scale, duration: interval)
    }
}

public struct Fade: Runnable {
    public let action: SKAction
    
    public static func `in`(over interval: TimeInterval = 1) -> Fade {
        Fade(to: 1, over: interval)
    }
    
    public static func out(over interval: TimeInterval = 1) -> Fade {
        Fade(to: 0, over: interval)
    }
    
    public init(to amount: Double, over interval: TimeInterval = 1) {
        action = .fadeAlpha(to: amount, duration: interval)
    }
    
    public init(by amount: Double, over interval: TimeInterval = 1) {
        action = .fadeAlpha(by: amount, duration: interval)
    }
}

public struct Colorize: Runnable {
    public let action: SKAction
    
    public init(with color: UIColor, colorBlendFactor: CGFloat = 0.5, over interval: TimeInterval = 1) {
        action = .colorize(with: color, colorBlendFactor: colorBlendFactor, duration: interval)
    }
}

public struct Hide: Runnable {
    public var action: SKAction = .hide()
    
    public init() {}
}

public struct Unhide: Runnable {
    public let action: SKAction = .unhide()
    
    public init() {}
}

public struct PlaySound: Runnable {
    public let action: SKAction
    
    public init(_ file: String, waitUntilPlaybackEnds wait: Bool = false) {
        action = .playSoundFileNamed(file, waitForCompletion: wait)
    }
}

public struct Remove: Runnable {
    public let action: SKAction = .removeFromParent()
    
    public init() {}
}

public struct Custom: Runnable {
    public let action: SKAction
    
    public init(over interval: TimeInterval = .zero, block: @escaping (_ targetNode: SKNode, _ elapsedTime: CGFloat) -> Void) {
        action = .customAction(withDuration: interval, actionBlock: block)
    }
    
    public init(block: @escaping () -> Void) {
        action = .run(block)
    }
}
