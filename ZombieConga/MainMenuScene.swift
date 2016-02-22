//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Wong You Jing on 19/02/2016.
//  Copyright © 2016 NoNonsense. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {

    
    override func didMoveToView(view: SKView) {
        let background = SKSpriteNode(imageNamed: "MainMenu")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1
        addChild(background)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        sceneTapped()
    }
    
    func sceneTapped(){
        let gameScene = GameScene(size: size)
        let reveal = SKTransition.doorsOpenHorizontalWithDuration(1.5)
        view?.presentScene(gameScene, transition: reveal)
    }
}