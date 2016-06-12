//
//  GameViewController.swift
//  story
//

import SceneKit
import QuartzCore
import AVFoundation

class GameViewController: NSViewController, SCNPhysicsContactDelegate {

    let ROTATE_SHIP = CGFloat(3)
    let GRAVITY     = CGFloat(-5)

    let KEY_SPACE   = UInt16(49)
    let KEY_W       = UInt16(13)
    let KEY_A       = UInt16(0)
    let KEY_S       = UInt16(1)
    let KEY_D       = UInt16(2)
    let KEY_UP      = UInt16(126)
    let KEY_DOWN    = UInt16(125)
    let KEY_RIGHT   = UInt16(123)
    let KEY_LEFT    = UInt16(124)
    let KEY_I       = UInt16(34)
    let KEY_J       = UInt16(38)
    let KEY_K       = UInt16(40)
    let KEY_L       = UInt16(37)
    let KEY_M       = UInt16(46)


    let cameraNode = SCNNode()
    var ship : SCNNode?
    var ground : SCNNode?

    enum Direction {
        case front
        case back
        case right
        case left
        case up
        case down
    }

    @IBOutlet weak var gameView: GameView!

    var sounds = [AVAudioPlayer]()
    func loadSounds() {
        
        for i in 0...9 {
            let name = "explosion" + String(i)
            let path = NSBundle.mainBundle().pathForResource(name, ofType: "mp3")!
            let url = NSURL(fileURLWithPath: path)
            do {
                let audioPlayer = try AVAudioPlayer(contentsOfURL: url)
                audioPlayer.prepareToPlay()
                sounds.append(audioPlayer)
            } catch {
                print("could not load " + name)
            }
        }
    }
    
    var timers = [UInt16:NSTimer]()

    func keyTimer(timer:NSTimer) {
        let key = timer.userInfo as! Int
        keyed(UInt16(key))
    }
    
    func keyed(key:UInt16) -> Bool {
        
        switch key {
            case KEY_W:     self.moveTowards(.up)
            case KEY_A:     self.moveTowards(.left)
            case KEY_S:     self.moveTowards(.down)
            case KEY_D:     self.moveTowards(.right)
            case KEY_UP:    self.moveTowards(.front)
            case KEY_DOWN:  self.moveTowards(.back)
            case KEY_LEFT:  self.turn(.left)
            case KEY_RIGHT: self.turn(.right)
            case KEY_I:     self.turnCamera(.up)
            case KEY_J:     self.turnCamera(.left)
            case KEY_K:     self.turnCamera(.back)
            case KEY_L:     self.turnCamera(.right)
            case KEY_M:     self.turnCamera(.down)
            case KEY_SPACE:   self.turnCamera(.front)
            default : return false
        }
        return true
    }
    
    override func keyDown(theEvent: NSEvent) {

        let key = theEvent.keyCode
        if timers[key] != nil {
            return
        }

        if !keyed(key) { // if I didn't use that key then
            interpretKeyEvents([theEvent]) // OSX can have it
        
            // keep repeating some keys until key-up
        } else if [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT].contains(key) {
            let timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(keyTimer), userInfo: Int(key), repeats: true)
            timers[key] = timer
        }
    }
    
    override func keyUp(theEvent: NSEvent) {
        let key = theEvent.keyCode
        if let timer = timers[key] {
            timer.invalidate()
            timers[key] = nil
        }
    }

    func moveTowards(direction:Direction) {
        let d = facing(self.ship!, face:direction)
        self.ship!.physicsBody?.applyForce(d, impulse:true)
    }

    func turnCamera(direction:Direction) {
        var p=CGFloat(0), q=p, r=q
        var x=CGFloat(0), y=x, z=y
        switch(direction) {
            case .front:
                z = 50
            case .back:
                z = -50
                q = CGFloat(M_PI)
            case .right:
                x = 50
                q = CGFloat(M_PI_2)
            case .left:
                x = -50
                q = -CGFloat(M_PI_2)
            case .up:
                y = -50
                p = CGFloat(M_PI_2)
            case .down:
                y = 50
                p = -CGFloat(M_PI_2)
        }
        self.cameraNode.eulerAngles = SCNVector3(x:p,y:q,z:r)
        self.cameraNode.position = SCNVector3(x:x, y:y, z:z)

    }

    func turn(direction:Direction) {
        var t : SCNVector4
        switch direction {
            case .right: t = SCNVector4(0,-1,0,-1)
            case .left: t = SCNVector4(0,1,0,-1)
            default: t = SCNVector4(0,0,0,0)
        }
        self.ship!.physicsBody?.applyTorque(t, impulse:true)
    }

    func whereAmI() -> SCNVector3 {
        return self.ship!.presentationNode.eulerAngles
    }

    func facing(node:SCNNode, face:Direction) -> SCNVector3 {

        let c = self.whereAmI()
        var x,y,z : CGFloat
        switch(face) {
            case .front:
                x = -sin(c.y)
                y = -sin(c.x) * sin(c.z)
                z = -cos(c.y) * cos(c.x)
            case .back:
                x = sin(c.y)
                y = sin(c.x) * sin(-c.z)
                z = cos(c.y) * cos(c.x)
            case .up:
                x = sin(c.z)
                y = cos(c.x) * cos(c.z)
                z = sin(c.x)
            case .down:
                x = -sin(c.z)
                y = -cos(c.x) * cos(c.z)
                z = -sin(c.x)
            case .right:
                x = cos(c.z) * cos(c.y)
                y = sin(c.x) * sin(c.z)
                z = sin(c.x) * sin(c.y)
            case .left:
                x = -cos(c.z) * cos(c.y)
                y = -sin(c.x) * sin(c.z)
                z = -sin(c.x) * sin(c.y)
        }

        x = normalize(x)
        y = normalize(y) / abs(y + 0.1) // takes off faster
        z = normalize(z)

        return SCNVector3(x,y,z)
    }

    // I forget what this does but it's probably useful
    func normalize(v:CGFloat) -> CGFloat {
        let k = CGFloat(5.0)
        let s = CGFloat(v < 0 ? -1.0 : 1.0)
        let r = floor(abs(v*k)) * s
        return r
    }

    func loadNode(path:String) -> SCNNode {
        if let scene = SCNScene(named: path) {

            let node = SCNNode()

            let nodeArray = scene.rootNode.childNodes
            for childNode in nodeArray {
                node.addChildNode(childNode as SCNNode)
            }
            return node

        } else {
            print("Invalid path supplied")
            return SCNNode()
        }
    }

    override func awakeFromNib(){
        super.awakeFromNib()
        loadSounds()
        self.makeScene()

//        self.gameView.delegate = self
    }

    func makeLight(scene:SCNScene) {
        // create and add a light to the scene
        let lightNode = SCNNode()
        let omni = SCNLight()
        omni.type = SCNLightTypeOmni
        lightNode.light = omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)

        // create and add an ambient light to the scene
        let ambient = SCNLight()
        ambient.type = SCNLightTypeAmbient
        ambient.color = NSColor.darkGrayColor()
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambient
        scene.rootNode.addChildNode(ambientLightNode)
    }

    func xmakeShix() {
        self.ship = loadNode("star-wars-vader-tie-fighter 2")
        ship!.position.y += 10
        ship!.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
        ship!.physicsBody!.categoryBitMask = CollisionTypes.Ship.rawValue
        ship!.physicsBody?.contactTestBitMask = CollisionTypes.Shape.rawValue
        ship?.presentationNode.eulerAngles.y = ROTATE_SHIP
        self.addNodeToRoot(ship!)
    }

    func cgfrand(range:Int) -> CGFloat {
        return CGFloat(drand48() * Double(range))
    }

    func randomShape() -> SCNGeometry {
        let p0 = cgfrand(100)
        let p1 = cgfrand(100)
        let p2 = cgfrand(100)
        let p3 = cgfrand(100)
        let h = cgfrand(500)

        let geometries = [SCNSphere(radius:p0),
            SCNPlane(width: p0, height: h),
            SCNBox(width: p0, height: h, length: p2, chamferRadius: p3),
            SCNPyramid(width: p0, height: h, length: p2),
            SCNCylinder(radius: p0, height: h),
            SCNCone(topRadius: p0, bottomRadius: p1, height: p2),
            SCNTorus(ringRadius: p0, pipeRadius: p1),
            SCNTube(innerRadius: p0, outerRadius: p1, height: p2),
            SCNCapsule(capRadius: p0, height: h/2.0)]

        let geoIndex = Int(drand48() * Double(geometries.count))
        let geometry = geometries[geoIndex]
        let hue = CGFloat(drand48())
        let color = NSColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        geometry.firstMaterial?.diffuse.contents = color
        return geometry
    }

    func makeSetting() {

        for _ in 1...1000 {

            let geometry = randomShape()
            let x = CGFloat(drand48() * 5000) - 2500
            let z = CGFloat(drand48() * 5000) - 2500
            let shapeNode = SCNNode(geometry: geometry)
            shapeNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
            shapeNode.position = SCNVector3(x: x, y: 0, z: z)

            shapeNode.physicsBody?.categoryBitMask = CollisionTypes.Shape.rawValue
            shapeNode.physicsBody?.contactTestBitMask = CollisionTypes.Ship.rawValue

            self.addNodeToRoot(shapeNode)
        }
    }

    func makeRobot() {

        let ballGeometry = SCNSphere(radius: 3.0)
        let ballNode = SCNNode(geometry: ballGeometry)
        ballNode.physicsBody = SCNPhysicsBody(type: .Static, shape: nil)
        ballNode.position = SCNVector3(x: 0, y: 5, z: 0)

        let boxGeometry = SCNBox(width: 10.0, height: 10.0, length: 10.0, chamferRadius: 1.0)
        let myStar = SCNMaterial()
        let image = NSImage(named: "tile")
//        print("image " + String(image))
        myStar.diffuse.contents = image
        boxGeometry.materials = [myStar]
        let boxNode = SCNNode(geometry: boxGeometry)
        let p = SCNPhysicsBody(type: .Dynamic, shape: nil)
        p.angularDamping = CGFloat(0.9)
        p.angularVelocityFactor = SCNVector3(0.0, 1.0, 0.0)
        boxNode.physicsBody = p
        boxNode.position = SCNVector3(x: 0, y: 15.0, z: 0)
        boxNode.addChildNode(ballNode)

        boxNode.physicsBody!.categoryBitMask = CollisionTypes.Ship.rawValue
        boxNode.physicsBody?.contactTestBitMask = CollisionTypes.Shape.rawValue

        self.addNodeToRoot(boxNode)
        ship = boxNode
    }

    func makeCamera() {
        let camera = SCNCamera()
        camera.automaticallyAdjustsZRange = true
        cameraNode.camera = camera
//        cameraNode.position = SCNVector3(x: 0, y: 10, z: 50)
        self.turnCamera(.front)

        ship!.addChildNode(cameraNode)
    }
    
    var n = 1

    enum CollisionTypes: Int {
        case Ship = 1
        case Floor = 2
        case Shape = 4
    }
    

    func detectContact(contact: SCNPhysicsContact) -> SCNNode? {
        if (ship == contact.nodeA ) {
            return contact.nodeB
        }
        if (ship == contact.nodeB) {
            return contact.nodeA
        }
        return nil
    }
    
    func playSound() {
        let range = sounds.count-1
        let index = Int(arc4random_uniform(UInt32(range)))
        let sound = sounds[index]
        sound.play()
    }

    func physicsWorld(world: SCNPhysicsWorld, didBeginContact contact: SCNPhysicsContact) {
        
        if let contacted = detectContact(contact) {
            let particleSystem = SCNParticleSystem(named: "Explosion", inDirectory: nil)
            let systemNode = SCNNode()
            systemNode.addParticleSystem(particleSystem!)
            systemNode.position = contacted.position
            self.addNodeToRoot(systemNode)
            contacted.removeFromParentNode()
            playSound()
        }
    }

    func makeScene() {

        let scene = SCNScene()
        scene.physicsWorld.gravity = SCNVector3(0,GRAVITY,0)
        scene.physicsWorld.contactDelegate = self

        scene.background.contents = [NSImage(named: "sky0") as NSImage!,
                                     NSImage(named: "sky1") as NSImage!,
                                     NSImage(named: "sky2") as NSImage!,
                                     NSImage(named: "sky3") as NSImage!,
                                     NSImage(named: "sky4") as NSImage!,
                                     NSImage(named: "sky5") as NSImage!]

        self.gameView!.scene = scene
        self.makeSetting()
        self.makeRobot()
        self.makeCamera()
        self.makeLight(scene)
        self.makeGround()
        self.gameView!.allowsCameraControl = true
        self.gameView!.showsStatistics = true
        self.gameView!.backgroundColor = NSColor.blackColor()
    }

    func addNodeToRoot(node:SCNNode) {
        self.gameView!.scene?.rootNode.addChildNode(node)
    }

    func makeGround() {
        let groundGeometry = SCNFloor()
        groundGeometry.reflectivity = 0.5
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = NSColor.blueColor()
        groundGeometry.materials = [groundMaterial]
        self.ground = SCNNode(geometry: groundGeometry)

        let groundShape = SCNPhysicsShape(geometry: groundGeometry, options: nil)
        let groundBody = SCNPhysicsBody(type: .Kinematic, shape: groundShape)
        ground!.physicsBody = groundBody
        ground!.physicsBody!.categoryBitMask = CollisionTypes.Floor.rawValue
        ground!.physicsBody!.contactTestBitMask = 0

        self.addNodeToRoot(ground!)
    }
}
