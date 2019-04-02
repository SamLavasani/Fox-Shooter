//
//  GameScene.swift
//  FoxShooter
//
//  Created by Samuel Lavasani on 2019-01-11.
//  Copyright © 2019 Samuel Lavasani. All rights reserved.
//

import SpriteKit
import GameplayKit
import UIKit

class GameScene: SKScene {
    
    var fox = SKSpriteNode()
    var timer = Timer()
    var resetButton = UIButton()
    var restartButton = UIButton()
    var gameOverLabel = UILabel()
    
    var customButton : UIButton {
        let button = UIButton()
        button.setTitleColor(.red, for: .normal)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.red.cgColor
        button.layer.cornerRadius = 25
        return button
    }
    
    let shotCategory : UInt32 = 0x1 << 0
    let ballonCategory : UInt32 = 0x1 << 1
    var scoreLabel = SKLabelNode()
    var lifeLabel = SKLabelNode()
    
    var foxWalk: SKAction?
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var life = 5 {
        didSet {
            lifeLabel.text = "Life: \(life)"
        }
    }
    
    override func didMove(to view: SKView) {
        if let node = self.childNode(withName: "fox") as? SKSpriteNode {
            let xRange = SKRange(lowerLimit:-320,upperLimit:320)
            fox = node
            fox.constraints = [SKConstraint.positionX(xRange)]
        }
        
        foxWalk = SKAction(named: "foxWalk")
        fox.removeAllActions()
        self.physicsWorld.contactDelegate = self
        let backgroundMusic = SKAudioNode(fileNamed: "fox-bgmusic.mp3")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
        setupUI()
        movingClouds()
        scheduledTimerWithTimeInterval()
        sendBalloon()
        if(life == 0) {
            life = 5
            resetScore()
        }
    }
    
    func setupButtons() {
        restartButton = customButton
        restartButton.frame = CGRect(x: UIScreen.main.bounds.width/2 - 100, y: UIScreen.main.bounds.height/2, width: 200, height: 50)
        restartButton.setTitle("Restart", for: .normal)
        restartButton.addTarget(self, action: #selector(restartGame), for: .touchUpInside)
        restartButton.isHidden = true
        view?.addSubview(restartButton)
    }
    
    func setupUI() {
        setupButtons()
        setupGameOverLabel()
        setupScoreLabel()
        setupLifeLabel()
    }
    
    func showRestartButton() {
        restartButton.isHidden = false
    }
    
    @objc func resetScore() {
        self.score = 0
        UserDefaults.standard.set(self.score, forKey: "Score")
    }
    
    @objc func restartGame() {
        restartButton.isHidden = true
        gameOverLabel.isHidden = true
        resetScore()
        life = 5
        UserDefaults.standard.set(self.life, forKey: "Life")
        scheduledTimerWithTimeInterval()
    }
    
    
    //MARK: Functions
    func setupScoreLabel() {
        score = UserDefaults.standard.integer(forKey: "Score")
        scoreLabel.name = "ScoreLabel"
        scoreLabel.fontColor = .yellow
        scoreLabel.fontSize = 30
        scoreLabel.zPosition = 2
        scoreLabel.position = CGPoint(x: -260, y: 150)
        addChild(scoreLabel)
    }
    
    func setupLifeLabel() {
        life = UserDefaults.standard.integer(forKey: "Life")
        lifeLabel.name = "LifeLabel"
        lifeLabel.fontColor = .yellow
        lifeLabel.fontSize = 30
        lifeLabel.zPosition = 2
        lifeLabel.position = CGPoint(x: 280, y: 150)
        addChild(lifeLabel)
    }
    
    func setupGameOverLabel() {
        gameOverLabel.frame = CGRect(x: UIScreen.main.bounds.width/2 - 100, y: UIScreen.main.bounds.height/4, width: 200, height: 60)
        gameOverLabel.textAlignment = .center
        gameOverLabel.text = "Game Over"
        gameOverLabel.textColor = .red
        gameOverLabel.font = UIFont(name: "Avenir Next", size: 30)
        gameOverLabel.isHidden = true
        view?.addSubview(gameOverLabel)
    }
    
    func showGameOver() {
        gameOverLabel.isHidden = false
    }
    
    func scheduledTimerWithTimeInterval(){
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.sendBalloon), userInfo: nil, repeats: true)
    }
    
    func movingClouds() {
        let cloud1 = SKSpriteNode(imageNamed: "cloudA")
        cloud1.xScale = 1
        cloud1.yScale = 1
        cloud1.position = CGPoint(x: 550, y: 90)
        cloud1.lightingBitMask = 1
        cloud1.name = "Moln1"
        cloud1.zPosition = 1
        
        let cloud2 = SKSpriteNode(imageNamed: "cloudB")
        cloud2.xScale = 1
        cloud2.yScale = 1
        cloud2.position = CGPoint(x: 900, y: 90)
        cloud2.lightingBitMask = 1
        cloud2.name = "Moln2"
        cloud2.zPosition = 1
        
        let cloud1Action = SKAction.moveBy(x: -1200, y: 0, duration: 18)
        let cloud2Action = SKAction.moveBy(x: -1500, y: 0, duration: 26)
        
        cloud1.run(cloud1Action) {
            cloud1.removeFromParent()
            self.movingClouds()
        }
        cloud2.run(cloud2Action) {
            cloud2.removeFromParent()
        }
        addChild(cloud1)
        addChild(cloud2)
    }
    
    func walkFox(_ touches: Set<UITouch>) {
        if let touch = touches.first {
            let touchPoint = touch.location(in: view)
            let foxLocation = fox.position
            let touchLocation = convertPoint(fromView: touchPoint)
            
            if let foxAction = foxWalk {
                fox.run(foxAction)
            }
            
            let a = touchLocation.x - foxLocation.x
            let c = sqrt(a*a)
            let v = 500.0
            let time = Double(c)/v
            
            if(a > 0) {
                //Go left
                fox.xScale = -0.5
            } else {
                //Go right
                fox.xScale = 0.5
            }
            
            let moveAction = SKAction.moveTo(x: touchLocation.x, duration: time)
            fox.run(moveAction) {
                self.fox.removeAllActions()
                self.fox.texture = SKTexture(imageNamed: "fox.png")
                self.fireShot(touches)
            }
            
        }
    }
    
    func fireShot(_ touches: Set<UITouch>){
        if let touch = touches.first {
            let foxPosition = fox.position
            let touchPoint = touch.location(in: view)
            let touchLocation = convertPoint(fromView: touchPoint)
            
            let a = touchLocation.x - foxPosition.x
            
            let shot = SKSpriteNode(imageNamed: "shot")
            shot.xScale = 0.02
            shot.yScale = 0.02
            shot.position = CGPoint(x: touchLocation.x, y: foxPosition.y + 50)
            shot.name = "Skott"
            shot.zPosition = 2
            let shotAction = SKAction.moveBy(x: a, y: 500, duration: 0.5)
            shot.run(shotAction) {
                shot.removeFromParent()
                if(self.score > 0) {
                    self.score -= 1
                    UserDefaults.standard.set(self.score, forKey: "Score")
                }
                self.missedShot()
            }
            addChild(shot)
            
            shot.physicsBody = SKPhysicsBody(rectangleOf: shot.frame.size)
            shot.physicsBody?.categoryBitMask = shotCategory
            shot.physicsBody?.collisionBitMask = shotCategory | ballonCategory
            shot.physicsBody?.contactTestBitMask = shotCategory | ballonCategory
            shot.physicsBody?.affectedByGravity = false
            shot.physicsBody?.usesPreciseCollisionDetection = true
        }
    }
    
    func missedShot(){
        let missedLabel = SKLabelNode(text: "MISS!")
        missedLabel.fontColor = .red
        missedLabel.fontSize = 60
        missedLabel.fontName = "Avenir Next"
        missedLabel.zPosition = 2
        missedLabel.position = CGPoint(x: 0, y: 0)
        self.addChild(missedLabel)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: {
            missedLabel.removeFromParent()
        })
    }
    
    fileprivate func loseLife() {
        if(self.life > 0) {
            self.life -= 1
            UserDefaults.standard.set(self.life, forKey: "Life")
            if(self.life == 0){
                //End game
                self.timer.invalidate()
                self.removeBallons()
                self.showRestartButton()
                self.showGameOver()
            }
        }
    }
    
    func removeBallons() {
        for child in self.children {
            if child.name == "Ballong" {
                child.removeFromParent()
            }
        }
    }
    
    @objc func sendBalloon(){
        let randomBallon = Int.random(in: 1...5)
        let randomYPosition = Int.random(in: 0...130)
        var balloonSpeed = Int.random(in: 3...10)
        let ballonScale = CGFloat.random(in: 0.8 ... 1.5)
        if(score > 10) { balloonSpeed = Int.random(in: 3...5)}
        
        let balloon = SKSpriteNode(imageNamed: "balloon\(randomBallon)")
        balloon.xScale = ballonScale
        balloon.yScale = ballonScale
        balloon.position = CGPoint(x: 400, y: randomYPosition)
        balloon.name = "Ballong"
        balloon.zPosition = 2
        
        let ballonAction = SKAction.moveBy(x: -800, y: 0, duration: Double(balloonSpeed))
        balloon.run(ballonAction) {
            balloon.removeFromParent()
            self.loseLife()
        }
        
        balloon.physicsBody = SKPhysicsBody(rectangleOf: balloon.frame.size)
        balloon.physicsBody?.categoryBitMask = ballonCategory
        balloon.physicsBody?.collisionBitMask = shotCategory
        balloon.physicsBody?.contactTestBitMask = shotCategory
        balloon.physicsBody?.affectedByGravity = false
        balloon.physicsBody?.usesPreciseCollisionDetection = true
        
        addChild(balloon)
    }

    //MARK: Touch Functions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        fox.removeAllActions()
        walkFox(touches)
    }
}

extension GameScene : SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        if let firstNode = contact.bodyA.node as? SKSpriteNode, let secondNode = contact.bodyB.node as? SKSpriteNode {
            //print("\(String(describing: firstNode.name)) collided with \(String(describing: secondNode.name))")
            if(firstNode.name == "Ballong" && secondNode.name == "Skott" || firstNode.name == "Skott" && secondNode.name == "Ballong"){
                
                if(firstNode.name == "Ballong"){
                    firstNode.texture = SKTexture(imageNamed: "balloon_explode")
                } else {
                    secondNode.texture = SKTexture(imageNamed: "balloon_explode")
                }
                
                firstNode.removeAllActions()
                secondNode.removeAllActions()
                self.score += 1
                UserDefaults.standard.set(self.score, forKey: "Score")
                run(SKAction.playSoundFileNamed("balloon-pop-sound.mp3", waitForCompletion: false))
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50), execute: {
                    firstNode.removeFromParent()
                    secondNode.removeFromParent()
                })
            }
        }
    }
}
