# ActionBuilder

**Caveat developer**: As this package is pre-release, the API may change significantly without notice. It has not been tested, so use it at your own risk.

ActionBuilder allows you to write SpriteKit animations in a more succinct, declarative manner. It consists of various structs representing basic animations like `Scale` and `Rotate`.

Creating an animation with SKActions:
```swift
static let emoteAction: SKAction = {
    let fadeIn = SKAction.fadeIn(withDuration: 0.7)
    let grow = SKAction.scale(by: 1.5, duration: 0.7)
    let moveUp = SKAction.moveTo(y: 30, duration: 0.7)
    let appear = SKAction.group([fadeIn, grow, moveUp])
    let wait = SKAction.wait(forDuration: 1)
    let disappear = SKAction.fadeOut(withDuration: 1)
    let remove = SKAction.removeFromParent()
    let emoteAnimation = SKAction.sequence([appear, wait, disappear, remove])
    return emoteAnimation
}()
```

The same animation created with ActionBuilder:
```swift
static let emote =
Sequence {
    Group {
        FadeIn(duration: 0.7)
        Scale(by: 1.5, duration: 0.7)
        Move(to: (0, 30), duration: 0.7)
    }
    Wait(0.5)
    FadeOut(duration: 1)
    Remove()
}
```

ActionBuilder allows you to use conditional and looping statements within your animation declaration to make them more flexible and easier to write.

Coordinate animations across multiple nodes with the `changeTarget(to:)` modifier.

Custom operators included: `+` will concatenate actions into a sequence, `&` will group them to run simultaneously, `-` will reverse reversible actions, and `*` allows you to repeat an action multiple times.

You can even include `SKAction`s if no equivalent is available in ActionBuilder.

```swift
let node = SKNode()
let otherNode = SKNode()

node.run {
    Group {
        
        Sequence {
            for i in 0...9 {
                Colorize(with: UIColor(red: Double(i/10), green: 0.7, blue: 0.7, alpha: 1))
                Wait(0.2)
            }
        }
        .changeTarget(to: otherNode)
        
        Sequence {
            let moveUp = Move(by: (0, 10))
            if Bool.random() {
                moveUp * 2
            } else {
                -moveUp
            }
            
            SKAction.resize(toHeight: 20, duration: 5)
        }
    }
}
```

See Apple's documentation: https://developer.apple.com/documentation/spritekit/skaction/action_initializers
