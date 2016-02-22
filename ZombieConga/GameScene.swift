//
//  GameScene.swift
//  ZombieConga
//
//  Created by Wong You Jing on 17/02/2016.
//  Copyright (c) 2016 NoNonsense. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    let cameraNode = SKCameraNode()
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    let zombieAnimation: SKAction
    var zombieInvincible = false
    
    var lives = 5
    var cats = 0
    var gameOver = false
    
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    
    let zombieMovePointsPerSec: CGFloat = 480.0
    let catMovePoints: CGFloat = 480.0
    let zombieRotateRadiansPerSec: CGFloat = π
    let cameraMovePointsPerSec: CGFloat = 200.0
    var velocity = CGPoint.zero
    
    var lastTouchLocation: CGPoint?
    
    let playableRect: CGRect
    
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed(
        "hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed(
        "hitCatLady.wav", waitForCompletion: false)
    
    let livesLabel = SKLabelNode(fontNamed: "Glimstick")
    let catsLabel = SKLabelNode(fontNamed: "Glimstick")
    
    var cameraRect : CGRect {
        return CGRect(
            x: getCameraPosition().x - size.width/2 + (size.width - playableRect.width)/2,
            y: getCameraPosition().y - size.width/2 + (size.height - playableRect.height)/2,
            width: playableRect.width,
            height: playableRect.height
        )
    }
    
    override init(size: CGSize){
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        
        var textures:[SKTexture] = []
        for i in 1...4{
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        
        zombieAnimation = SKAction.animateWithTextures(textures, timePerFrame: 0.1)
        super.init(size: size)
    }
    
    required init(coder aDecoder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        playBackgroundMusic("backgroundMusic.mp3")
        backgroundColor = SKColor.blackColor()
        for i in 0...1{
            let background = backgroundNode()
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: CGFloat(i) * background.size.width, y: 0)
            background.name = "background"
            background.zPosition = -1
            addChild(background)
        }
        zombie.zPosition = 100
        zombie.position = CGPoint(x: 400, y: 400)
        addChild(zombie)
        
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([SKAction.runBlock(spawnEnemy),
            SKAction.waitForDuration(2.0)])))
        runAction(SKAction.repeatActionForever(
                SKAction.sequence([SKAction.runBlock(spawnCat),
                SKAction.waitForDuration(1.0)])))
        debugDrawPlayableArea()
        addChild(cameraNode)
        camera = cameraNode
        setCameraPosition(CGPoint(x: size.width/2, y: size.height/2))
        
        livesLabel.text = "Lives: X"
        livesLabel.color = SKColor.blackColor()
        livesLabel.fontSize = 100
        livesLabel.zPosition = 100
        livesLabel.horizontalAlignmentMode = .Left
        livesLabel.verticalAlignmentMode = .Bottom
        livesLabel.position = CGPoint(x: -playableRect.size.width/2 +
            CGFloat(20),
            y: -playableRect.size.height/2 + CGFloat(20) + overlapAmount()/2)
        
        catsLabel.text = "Cats: 0"
        catsLabel.color = SKColor.blackColor()
        catsLabel.fontSize = 100
        catsLabel.zPosition = 100
        catsLabel.horizontalAlignmentMode = .Right
        catsLabel.verticalAlignmentMode = .Bottom
        catsLabel.position = CGPoint(x: playableRect.size.width/2 -
            CGFloat(20),
            y: -playableRect.size.height/2 + CGFloat(20) + overlapAmount()/2)
        
        cameraNode.addChild(catsLabel)
        cameraNode.addChild(livesLabel)
    }
    
    override func update(currentTime: NSTimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        }else{
            dt = 0
        }
        lastUpdateTime = currentTime
        
//        if let destination = lastTouchLocation {
//            let distanceRemainingToDestination = (destination - zombie.position).length()
//            if distanceRemainingToDestination < (zombieMovePointsPerSec * CGFloat(dt)) {
//                zombie.position = destination
//                velocity = CGPoint.zero
//                stopZombieAnimation()
//            }else{
                moveSprite(zombie, velocity: velocity)
                rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
//            }
//        }
        
        boundsCheckZombie()
        moveTrain()
        moveCamera()
        if lives <= 0 && !gameOver {
            gameOver = true
            print("You lose!")
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
        

    }
    
    override func didEvaluateActions()  {
        checkCollisions()
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint){
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint) {
        startZombieAnimation()
        let offset = location - zombie.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
    }
    
    func sceneTouched(touchLocation: CGPoint){
        moveZombieToward(touchLocation)
        lastTouchLocation = touchLocation
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        print(touchLocation)
        sceneTouched(touchLocation)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        sceneTouched(touchLocation)
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: CGRectGetMinX(cameraRect), y: CGRectGetMinY(cameraRect))
        let topRight = CGPoint(x: CGRectGetMaxX(cameraRect), y: CGRectGetMaxY(cameraRect))
        
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    

    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, playableRect)
        shape.path = path
        shape.strokeColor = SKColor.redColor()
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint,
        rotateRadiansPerSec: CGFloat) {
            let shortest = shortestAngleBetween(sprite.zRotation, angle2: velocity.angle)
            let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
            sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(
        x: CGRectGetMaxX(cameraRect) + enemy.size.width/2,
        y: CGFloat.random(
            min: CGRectGetMinY(cameraRect) + enemy.size.height/2,
            max: CGRectGetMaxY(cameraRect) - enemy.size.height/2))
        enemy.zPosition = 50
        addChild(enemy)
        let actionMove = SKAction.moveByX(-cameraRect.width - enemy.size.width/2, y: 0, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func startZombieAnimation(){
        if zombie.actionForKey("animation") == nil {
            zombie.runAction(SKAction.repeatActionForever(zombieAnimation), withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeActionForKey("animation")
    }
    
    // zombie.runAction(
    //  SKAction.repeatActionForever(zombieAnimation))
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(
            x: CGFloat.random(  min: CGRectGetMinX(cameraRect),
                                max: CGRectGetMaxX(cameraRect)),
            y: CGFloat.random(  min: CGRectGetMinY(cameraRect),
                                max: CGRectGetMaxY(cameraRect)))
        cat.zPosition = 50
        cat.setScale(0)
        addChild(cat)
        let appear = SKAction.scaleTo(1.0, duration: 0.5)
            
        //cat wiggling
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotateByAngle(π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversedAction()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        //Cat scaling
        let scaleUp = SKAction.scaleBy(1.2, duration: 0.25)
        let scaleDown = scaleUp.reversedAction()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeatAction(group, count: 10)
            
        let disappear = SKAction.scaleTo(0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.runAction(SKAction.sequence(actions))
    }
    
    func zombieHitCat(cat: SKSpriteNode) {
        cats++
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1)
        let colorize = SKAction.colorizeWithColor(UIColor.greenColor(), colorBlendFactor: 1.0, duration: 0.2)
        cat.runAction(SKAction.group([catCollisionSound, colorize]))
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
        zombieInvincible = true
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customActionWithDuration(duration) { (node, elapsedTime) -> Void in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime) % slice
            self.zombie.hidden = remainder > slice / 2
        }
        runAction(enemyCollisionSound)
        loseCats()
        lives--
        runAction(blinkAction) { () -> Void in
            self.zombieInvincible = false
        }
    }
    
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodesWithName("cat") { (node, _) -> Void in
            let cat = node as! SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.zombie.frame){
                hitCats.append(cat)
            }
        }
        for cat in hitCats{
            zombieHitCat(cat)
        }
        
        if zombieInvincible{
            return
        }
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodesWithName("enemy") { (node, _) -> Void in
            let enemy = node as! SKSpriteNode
            if CGRectIntersectsRect(CGRectInset(node.frame, 20, 20), self.zombie.frame){
                hitEnemies.append(enemy)
            }
        }
        for enemy in hitEnemies {
            zombieHitEnemy(enemy)
        }
        
        
    }
    
    func moveTrain(){
        var trainCount = 0
        var targetPosition = zombie.position
        
        enumerateChildNodesWithName("train") { (node, _) -> Void in
            trainCount++
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePoints
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveByX(amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.runAction(moveAction)
            }
            targetPosition = node.position
        }
        if trainCount >= 15 && !gameOver {
            gameOver = true
            print("You win!")
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
        livesLabel.text = "Lives: \(lives)"
        catsLabel.text = "Cats: \(cats)"
    }
    
    func loseCats() {
        var loseCount = 0
        enumerateChildNodesWithName("train") { (node, stop) -> Void in
            var randomSpot = node.position
            randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            node.name = ""
            node.runAction(SKAction.sequence([
                    SKAction.group([
                        SKAction.rotateByAngle(π * 4, duration: 1.0),
                        SKAction.moveTo(randomSpot, duration: 1.0),
                        SKAction.scaleTo(0, duration: 1.0)
                    ]),
                    SKAction.removeFromParent()
                ]))
            loseCount++
            self.cats--
            if loseCount >= 2 {
                stop.memory = true
            }
        }
    }
    
    func overlapAmount() -> CGFloat {
        guard let view = self.view else {return 0 }
        let scale = view.bounds.size.width / self.size.width
        let scaledHeight = self.size.height * scale
        let scaledOverlap = scaledHeight - view.bounds.size.height
        return scaledOverlap / scale
    }
    
    func getCameraPosition() -> CGPoint {
        return CGPoint(x: cameraNode.position.x, y: cameraNode.position.y +
        overlapAmount()/2)
    }
    func setCameraPosition(position: CGPoint) {
        cameraNode.position = CGPoint(x: position.x, y: position.y -
        overlapAmount()/2)
    }
    
    func backgroundNode() -> SKSpriteNode {
        // 1
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        // 2
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        // 3
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position =
            CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        // 4
        backgroundNode.size = CGSize(
            width: background1.size.width + background2.size.width,
            height: background1.size.height)
        return backgroundNode
    }
    
    func moveCamera() {
        let backgroundVelocity =
        CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        enumerateChildNodesWithName("background") { (node, _) -> Void in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width < self.cameraRect.origin.x {
                background.position = CGPoint(x: background.position.x + background.size.width * 2, y: background.position.y)
            }
        }
    }
}
