//
//  GameViewController.swift
//  story
//

import SceneKit
import GameKit
import QuartzCore
import AVFoundation

enum CollisionType: Int {
    case None = 0
    case Ship = 1
    case Floor = 2
    case Shape = 4
    case Bank = 8
    case Collector = 16
}

class GameViewController: NSViewController, SCNPhysicsContactDelegate {

    static var shared : GameViewController?
    
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
    var credits = 0

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
            let path = Bundle.main().pathForResource(name, ofType: "mp3")!
            let url = NSURL(fileURLWithPath: path)
            do {
                let audioPlayer = try AVAudioPlayer(contentsOf: url as URL)
                audioPlayer.prepareToPlay()
                sounds.append(audioPlayer)
            } catch {
                print("could not load " + name)
            }
        }
    }
    
    var timers = [UInt16:Timer]()

    func keyTimer(timer:Timer) {
        let key = timer.userInfo as! Int
        _ = keyed(key: UInt16(key))
    }
    
    func keyed(key:UInt16) -> Bool {
        
//        print("key \(key)")
        switch key {
            case KEY_W:     self.moveTowards(direction: .up)
            case KEY_A:     self.moveTowards(direction: .left)
            case KEY_S:     self.moveTowards(direction: .down)
            case KEY_D:     self.moveTowards(direction: .right)
            case KEY_UP:    self.moveTowards(direction: .front)
            case KEY_DOWN:  self.moveTowards(direction: .back)
            case KEY_LEFT:  self.turn(direction: .left)
            case KEY_RIGHT: self.turn(direction: .right)
            case KEY_I:     self.turnCamera(direction: .up)
            case KEY_J:     self.turnCamera(direction: .left)
            case KEY_K:     self.turnCamera(direction: .back)
            case KEY_L:     self.turnCamera(direction: .right)
            case KEY_M:     self.turnCamera(direction: .down)
            case KEY_SPACE: self.turnCamera(direction: .front)
            
        default : return false
        }
        return true
    }
    
    override func keyDown(_ theEvent: NSEvent) {

        let key = theEvent.keyCode
        if timers[key] != nil {
            return
        }

        if !keyed(key: key) { // if I didn't use that key then
            interpretKeyEvents([theEvent]) // OSX can have it
        
            // keep repeating some keys until key-up
        } else if [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT].contains(key) {
            let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(keyTimer), userInfo: Int(key), repeats: true)
            timers[key] = timer
        }
    }
    
    override func keyUp(_ theEvent: NSEvent) {
        let key = theEvent.keyCode
        if let timer = timers[key] {
            timer.invalidate()
            timers[key] = nil
        }
    }

    func moveTowards(direction:Direction) {
        let d = facing(node: self.ship!, face:direction)
        self.ship!.physicsBody?.applyForce(d, impulse:true)
    }

    func turnCamera(direction:Direction) {
        var p=CGFloat(0), q=p, r=q
        var x=CGFloat(0), y=CGFloat(20), z=x
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
            case .right: t = SCNVector4(0,-10,0,-1)
            case .left: t = SCNVector4(0,10,0,-1)
            default: t = SCNVector4(0,0,0,0)
        }
        self.ship!.physicsBody?.applyTorque(t, impulse:true)
    }

    func whereAmI() -> SCNVector3 {
        return self.ship!.presentation.eulerAngles
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

        x = normalize(v: x)
        y = normalize(v: y) / abs(y + 0.1) // takes off faster
        z = normalize(v: z)

        return SCNVector3(x,y,z)
    }

    // I forget what this does but it's probably useful
    func normalize(v:CGFloat) -> CGFloat {
        let k = CGFloat(10.0)
        let s = CGFloat(v < 0 ? -1.0 : 1.0)
        let r = floor(abs(v*k)) * s
        return r
    }

    func loadNode(path:String) -> SCNNode {
        if let nodeScene = SCNScene(named: path) {

            let node = SCNNode()

            let nodeArray = nodeScene.rootNode.childNodes
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
        GameViewController.shared = self
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
        lightNode.position = SCNVector3(x: 100, y: 10, z: 100)
        scene.rootNode.addChildNode(lightNode)

        // create and add an ambient light to the scene
        let ambient = SCNLight()
        ambient.type = SCNLightTypeAmbient
        ambient.color = NSColor.darkGray()
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambient
        scene.rootNode.addChildNode(ambientLightNode)
    }

    func xmakeShix() {
        self.ship = loadNode(path: "star-wars-vader-tie-fighter 2")
        ship!.position.y += 10
        ship!.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        ship!.physicsBody!.categoryBitMask = CollisionType.Ship.rawValue
        ship!.physicsBody?.contactTestBitMask = CollisionType.Shape.rawValue
        ship?.presentation.eulerAngles.y = ROTATE_SHIP
        self.addNodeToRoot(node: ship!)
    }

    func cgfrand(range:Int) -> CGFloat {
        return CGFloat(drand48() * Double(range))
    }

    func randomShape() -> SCNGeometry {
        let p0 = cgfrand(range: 100)
        let p1 = cgfrand(range: 100)
        let p2 = cgfrand(range: 100)
        let p3 = cgfrand(range: 100)
        let h = cgfrand(range: 500)

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
            let x = Int(drand48() * 5000 - 2500)
            let z = Int(drand48() * 5000 - 2500)
            _ = YSnode(geometry:geometry, x:x, z:z, category:.Shape, contact:.Ship)
        }
    }

    func makeAwall(x:Int, z:Int, width:Int, length:Int) {
        for i in 0...width-1 {
            let dx = BRICK_SIDE * CGFloat(i)
            let dz = BRICK_SIDE * CGFloat(length-1)
            makeBrick(x: CGFloat(x)+dx, z:CGFloat(z), color:NSColor.red())
            makeBrick(x: CGFloat(x)+dx, z:CGFloat(z)+dz, color:NSColor.blue())
        }
        for j in 1...length-2 {
            let dx = BRICK_SIDE * CGFloat(width-1)
            let dz = BRICK_SIDE * CGFloat(j)
            makeBrick(x: CGFloat(x),    z:CGFloat(z)+dz, color: NSColor.green())
            makeBrick(x: CGFloat(x)+dx, z:CGFloat(z)+dz)
        }
    }
    
    let BRICK_SIDE = CGFloat(10)
    
    func connect(n:SCNNode, with:SCNNode?) {
        if with == nil {
            return
        }
        let v0 = SCNVector3Make(CGFloat(M_PI/2), 0, 0)
        var pa = n.position
        pa.x = pa.x + BRICK_SIDE / 2
        pa.z = pa.z + BRICK_SIDE / 2
        var pb = with!.position
        pb.x = pb.x + BRICK_SIDE / 2
        pb.z = pb.z + BRICK_SIDE / 2
        
        let rope = SCNPhysicsSliderJoint(bodyA: n.physicsBody!, axisA: v0, anchorA: pa, bodyB: with!.physicsBody!, axisB: v0, anchorB: pb)
//        let rope = SCNPhysicsHingeJoint(bodyA: n.physicsBody!, axisA: v0, anchorA: pa, bodyB: with!.physicsBody!, axisB: v0, anchorB: pb)
//        rope.maximumLinearLimit = BRICK_SIDE * 2
        self.gameView!.scene?.physicsWorld.add(rope)
    }
    
    func makeBrick(x:CGFloat, z:CGFloat, color:NSColor=NSColor.white()) {
        let geo = SCNBox(width: BRICK_SIDE, height: BRICK_SIDE, length: BRICK_SIDE, chamferRadius: 1.0)
        geo.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: geo)
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.position = SCNVector3(x: x, y: 0.0, z: z)
        node.physicsBody?.categoryBitMask = CollisionType.Shape.rawValue
        node.physicsBody?.mass = 100
        node.physicsBody?.friction = 100
        self.addNodeToRoot(node: node)
    }

    func makeRobot() {

        let ballGeometry = SCNSphere(radius: 3.0)
        let ballNode = SCNNode(geometry: ballGeometry)
        ballNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        ballNode.position = SCNVector3(x: 0, y: 5, z: 0)

        let boxGeometry = SCNBox(width: 10.0, height: 10.0, length: 10.0, chamferRadius: 2.0)
        let myStar = SCNMaterial()
        let image = NSImage(named: "tile")
        myStar.diffuse.contents = image
        boxGeometry.materials = [myStar]
        let boxNode = SCNNode(geometry: boxGeometry)
        let p = SCNPhysicsBody(type: .dynamic, shape: nil)
        p.angularDamping = CGFloat(0.9)
        p.angularVelocityFactor = SCNVector3(0.0, 1.0, 0.0)
        boxNode.physicsBody = p
        boxNode.position = SCNVector3(x: 0, y: 15.0, z: 0)
        boxNode.addChildNode(ballNode)

        boxNode.physicsBody!.categoryBitMask = CollisionType.Ship.rawValue
        boxNode.physicsBody?.contactTestBitMask = CollisionType.Shape.rawValue

        self.addNodeToRoot(node:boxNode)
        ship = boxNode
    }

    func makeCamera() {
        let camera = SCNCamera()
        camera.automaticallyAdjustsZRange = true
        cameraNode.camera = camera
        self.turnCamera(direction: .front)

        ship!.addChildNode(cameraNode)
    }
    
    func detectContact(contact: SCNPhysicsContact) {
        if let a = contact.nodeA as? YSnode, b = contact.nodeB as? YSnode {
            if a.type == .Bank || b.type == .Bank {
                self.credits = self.credits + 1
            }
        }
    }
    
    func playSound() {
        let range = sounds.count-1
        let index = Int(arc4random_uniform(UInt32(range)))
        let sound = sounds[index]
        sound.play()
    }

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        detectContact(contact: contact)
    }
    
    func collectorBump(other:YSnode) {
        
    }
    
    func shipBump(contacted:YSnode) {
        let particleSystem = SCNParticleSystem(named: "Explosion", inDirectory: nil)
        let systemNode = SCNNode()
        systemNode.addParticleSystem(particleSystem!)
        systemNode.position = contacted.position
        self.addNodeToRoot(node: systemNode)
        contacted.removeFromParentNode()
        playSound()
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
        self.makeLight(scene: scene)
        self.makeGround()
        self.gameView!.allowsCameraControl = true
        self.gameView!.showsStatistics = true
        self.gameView!.backgroundColor = NSColor.black()
        
        self.makeAwall(x: -100,z:-100,width:20, length:20)
        self.makeBank(x: 0, z:-30)
        for _ in 1...10 {
            _ = Collector(x: 30, z:30)
        }
    }

    func addNodeToRoot(node:SCNNode) {
        self.gameView!.scene?.rootNode.addChildNode(node)
    }

    func makeGround() {
        let groundGeometry = SCNFloor()
        groundGeometry.reflectivity = 0.5
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = NSColor.blue()
        groundGeometry.materials = [groundMaterial]
        self.ground = SCNNode(geometry: groundGeometry)

        let groundShape = SCNPhysicsShape(geometry: groundGeometry, options: nil)
        let groundBody = SCNPhysicsBody(type: .kinematic, shape: groundShape)
        ground!.physicsBody = groundBody
        ground!.physicsBody!.categoryBitMask = CollisionType.Floor.rawValue
        ground!.physicsBody!.contactTestBitMask = 0

        self.addNodeToRoot(node: ground!)
    }

    func makeBank(x:Int, z:Int) {
        let BANK_SIDE = BRICK_SIDE * 2
        let geo = SCNBox(width: BANK_SIDE, height: BANK_SIDE, length: BANK_SIDE, chamferRadius: 1.0)
        geo.firstMaterial?.diffuse.contents = NSColor.yellow()
        _ = YSnode(geometry:geo, x:x, z:z, category:.Bank, contact:.Collector)
    }
}

class Collector : YSnode {
    
    init(x:Int, z:Int) {
        let geo = SCNCylinder(radius: 10, height: 5)
        geo.firstMaterial?.diffuse.contents = NSColor.green()
        super.init(geometry:geo, x:x, z:z, category:.Collector, contact:.Bank)
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(moveCollectorTime), userInfo: nil, repeats: true)
    }
    
    static let MAGNITUDE = CGFloat(10)
    static func v() -> CGFloat {
        let a = CGFloat(drand48())
        let b = a * MAGNITUDE + MAGNITUDE / 2
        let c = drand48()*2
        let d = c > 1 ? b : -b
        return d
    }
    
    func moveCollectorTime(timer:Timer) {
        let dx = Collector.v()
        let dz = Collector.v()
        let direction = SCNVector3(dx,0,dz)
        self.physicsBody?.applyForce(direction, impulse:true)
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
}

class YSnode : SCNNode {

    var type : CollisionType { return CollisionType(rawValue:(self.physicsBody?.categoryBitMask)!)! }
    
    init(geometry:SCNGeometry, x:Int, z:Int, category:CollisionType, contact:CollisionType) {
        super.init()

        self.geometry = geometry
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        self.position = SCNVector3(x: CGFloat(x), y: 0, z: CGFloat(z))
        self.physicsBody?.categoryBitMask = category.rawValue
        self.physicsBody?.contactTestBitMask = contact.rawValue
        
        GameViewController.shared!.addNodeToRoot(node: self)
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
}
