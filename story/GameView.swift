//
//  GameView.swift
//  story
//
//  Created by Yusuf Saib on 4/24/16.
//  Copyright (c) 2016 x. All rights reserved.
//

import SceneKit

class GameView: SCNView {
    
    override func mouseDown(_ theEvent: NSEvent) {
        /* Called when a mouse click occurs */
        
        // check what nodes are clicked
        let p = self.convert(theEvent.locationInWindow, from: nil)
        let hitResults = self.hitTest(p, options: nil)
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: SCNHitTestResult = hitResults[0]
            
            Swift.print("hit \(result.node.geometry!.dynamicType) at \(result.localCoordinates)")
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
//            SCNTransaction.setCompletionBlock() {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = NSColor.black()
                
                SCNTransaction.commit()
//            }
            
            material.emission.contents = NSColor.red()
            
            SCNTransaction.commit()
        }
        
        super.mouseDown(theEvent)
    }

}
