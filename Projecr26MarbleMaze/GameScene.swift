//
//  GameScene.swift
//  Projecr26 MarbleMaze
//  Days 85-87
//  Created by Igor Polousov on 18.03.2022.
//

import SpriteKit
import CoreMotion

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
    case teleport = 32
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    var playerStartPosition: CGPoint!
    var isPortalActive = true
    
    var motionManager: CMMotionManager?
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var isGameOver = false
    
    override func didMove(to view: SKView) {
        
        playerStartPosition = CGPoint(x: 96, y: 672)
        
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 20, y: 20)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
        
        loadLevel()
        createPlayer(at: playerStartPosition)
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self // Устанавливается когда нужно получать сообщения о соприкосновении двух объектов
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
    }
    
    func loadLevel() {
        guard let levelUrl = Bundle.main.url(forResource: "level2", withExtension: "txt") else { fatalError("Couldn't find the level1.txt in the app bundle") }
        guard let levelString = try? String(contentsOf: levelUrl) else { fatalError("Couldn't find the level1.txt in the app bundle") }
        let lines = levelString.components(separatedBy: "\n")
        
        for (row,line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                
                if letter == "x" {
                  createWallBlock(position: position)
                    
                } else if letter == "v" {
                    createVortex(position: position)

                } else if letter == "s" {
                    createStar(position: position)

                } else if letter == "f" {
                    createFinish(position: position)

                } else if letter == "t" {
                    createTeleport(position: position)
                    
                } else if letter == " " {
                    // do nothing
                } else {
                    fatalError("Unknown level letter \(letter)")
                }
            }
        }
    }
    
    func createWallBlock(position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "xblock")
        node.position = position
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        node.physicsBody?.isDynamic = false
        addChild(node)
    }
    
    func createVortex(position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "vortex")
        node.name = "vortex"
        node.position = position
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func createStar(position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "star")
        node.name = "star"
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        node.position = position
        addChild(node)
    }
    
    func createFinish(position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "finish")
        node.position = position
        node.name = "finish"
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        node.physicsBody?.isDynamic = false
        addChild(node)
    }
   
    
    func createPlayer(at position: CGPoint) {
        player = SKSpriteNode(imageNamed: "player")
        player.position = position
        player.zPosition = 1
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.finish.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.teleport.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        addChild(player)
    }
    
    func createTeleport(position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "teleport")
        node.name = "teleport"
        node.position = position
        //node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.teleport.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        guard isGameOver == false else { return }
        
        #if targetEnvironment(simulator)
        if let lastTouchPosition = lastTouchPosition {
            let diff = CGPoint(x: lastTouchPosition.x - player.position.x, y: lastTouchPosition.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
        #else
        if let accelerometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
        #endif
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        if nodeA == player {
            playerCollided(with: nodeB)
        } else if nodeB == player {
            playerCollided(with: nodeA)
        }
    }
    
    func playerCollided(with node: SKNode) {
        
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            isGameOver =  true
            score -= 1
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence =  SKAction.sequence([move, scale, remove])
            
            player.run(sequence) { [weak self] in
                self?.loadLevel()
                self?.createPlayer(at: self!.playerStartPosition)
                self?.isGameOver = false
            }
            
            
        } else if node.name == "teleport" {
            
            let position = node.position
            if position != player.position {
                isPortalActive = true
            }
            guard isPortalActive else { return }

            player.physicsBody?.isDynamic = false

            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence =  SKAction.sequence([move, scale, remove])
            
            for node in children {
                if node.name == "teleport" && node.position != position {
                    player.run(sequence) { [weak self] in
                        self?.createPlayer(at: node.position)
                        self?.isPortalActive = false
                    }
                }
            }
           
        } else if node.name == "star" {
            node.removeFromParent()
            score += 1
            
        } else if node.name == "finish" {
            //go to  next level
        }
    }
}
