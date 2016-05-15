//
//  GameViewController.swift
//  story
//

import SceneKit
import QuartzCore

class GameViewController: NSViewController, SCNSceneRendererDelegate {

    let ROTATE_SHIP = CGFloat(3)
    let SPACE_BAR = UInt16(49)
    let cameraNode = SCNNode()
    var ship : SCNNode?

    enum Direction {
        case front
        case back
        case right
        case left
        case up
        case down
    }

    @IBOutlet weak var gameView: GameView!

    override func keyDown(theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
        if theEvent.keyCode == SPACE_BAR {
            let d = facing(self.ship!, face:.up)
            self.ship!.physicsBody?.applyForce(d, impulse:true)
        }
    }
    override func moveUp(sender: AnyObject?) {
        let d = facing(self.ship!, face:.front)
        self.ship!.physicsBody?.applyForce(d, impulse:true)
    }
    override func moveDown(sender: AnyObject?) {
        let d = facing(self.ship!, face:.back)
        self.ship!.physicsBody?.applyForce(d, impulse:true)
    }
    override func moveLeft(sender: AnyObject?) {
        let t = SCNVector4(0,-1,0,-1)
        self.ship!.physicsBody?.applyTorque(t, impulse:true)
    }
    override func moveRight(sender: AnyObject?) {
        let t = SCNVector4(0,1,0,-1)
        self.ship!.physicsBody?.applyTorque(t, impulse:true)
    }

    func whereAmI() -> SCNVector3 {
        print("euler \(self.ship!.presentationNode.eulerAngles)")
        let s = self.ship!.presentationNode.eulerAngles
        return s
    }

    func facing(node:SCNNode, face:Direction) -> SCNVector3 {

        let c = self.whereAmI()
        print("euler: " + String(c))
        var x,y,z : CGFloat
        switch(face) {
            case .front:
                x = sin(c.y)
                y = sin(c.x) * sin(c.z)
                z = cos(c.y) * cos(c.x)
            case .back:
                x = -sin(c.y)
                y = -sin(c.x) * sin(-c.z)
                z = -cos(c.y) * cos(c.x)
            case .up:
                x = sin(c.y)
                y = cos(c.x) * cos(c.z)
                z = sin(c.x) * sin(c.y)
            default:
                x = 0.0
                y = 0.0
                z = 0.0
        }
        return SCNVector3(x, y, z)
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

    func makeShip() {
        self.ship = loadNode("star-wars-vader-tie-fighter 2")
//        self.ship = loadNode("quad-bot")
        ship!.position.y += 10
        ship!.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
        ship?.presentationNode.eulerAngles.y = ROTATE_SHIP
        self.addNodeToRoot(ship!)
    }
    
    func makeSetting() {
        
        for _ in 1...10 {
            let height = CGFloat(drand48() * 100)
            let x = CGFloat(drand48() * 200) - 100
            let z = CGFloat(drand48() * 200) - 100
            let boxGeometry = SCNBox(width: 10.0, height: height, length: 10.0, chamferRadius: 1.0)
            let boxNode = SCNNode(geometry: boxGeometry)
            boxNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
            boxNode.position = SCNVector3(x: x, y: 0, z: z)
            
            self.addNodeToRoot(boxNode)
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
        print("image " + String(image))
        myStar.diffuse.contents = image
        boxGeometry.materials = [myStar]
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: nil)
        boxNode.position = SCNVector3(x: 0, y: 15.0, z: 0)
        boxNode.addChildNode(ballNode)
        
        
        self.addNodeToRoot(boxNode)
        ship = boxNode
    }

    func renderer(aRenderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval){

//        let cameraDamping = Float(0.3)

        let car: SCNNode = ship!.presentationNode
        let carPos: SCNVector3 = car.position
        let targetPos: vector_float3 = vector_float3(
            Float(carPos.x),
            10.0,
            Float(carPos.z) + 500.0)
//        var cameraPos = targetPos//: vector_float3 = SCNVector3ToFloat3(cameraNode.position)
//        cameraPos = vector_mix(cameraPos, targetPos, vector_float3(cameraDamping))
        self.cameraNode.position = SCNVector3FromFloat3(targetPos)
//        self.cameraNode.eulerAngles.y = 1
    }
    
    func makeCamera1() {
        let camera = SCNCamera()
        let cameraNode = SCNNode() // remove
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 10, z: 50)
        
        ship!.addChildNode(cameraNode)
    }
    
    func makeCamera() {
        let camera = SCNCamera()
//        camera.usesOrthographicProjection = true
//        camera.orthographicScale = 9
//        camera.zNear = 0
//        camera.zFar = 100000
        camera.automaticallyAdjustsZRange = true
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 50)
        cameraNode.camera = camera

        self.addNodeToRoot(cameraNode)
}
    
    // follows
    func makeCamera0() {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 9
        camera.zNear = 0
        camera.zFar = 100
        let cameraNode = SCNNode() // remove
        cameraNode.position = SCNVector3(x:0, y:100, z:50)
        
//        cameraNode.transform = CATransform3DRotate(cameraNode.transform, CGFloat(-M_PI)/7.0, 1, 0, 0)
//        cameraNode.eulerAngles.x -= CGFloat(M_PI_4)
//        cameraNode.eulerAngles.y -= CGFloat(M_PI_4*3)

        cameraNode.camera = camera
//        self.addNodeToRoot(cameraNode)
        self.addNodeToRoot(cameraNode)
    }

    func makeScene() {

        let scene = SCNScene()
        
        self.gameView!.scene = scene
        self.makeSetting()
//        self.makeShip()
        self.makeRobot()
        self.makeCamera1()
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
        groundGeometry.reflectivity = 1
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = NSColor.blueColor()
        groundGeometry.materials = [groundMaterial]
        let ground = SCNNode(geometry: groundGeometry)

        let groundShape = SCNPhysicsShape(geometry: groundGeometry, options: nil)
        let groundBody = SCNPhysicsBody(type: .Kinematic, shape: groundShape)
        ground.physicsBody = groundBody

        self.addNodeToRoot(ground)
    }
}
