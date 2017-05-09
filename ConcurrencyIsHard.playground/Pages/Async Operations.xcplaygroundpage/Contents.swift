//: [⬅ NSOperationQueue](@previous)
/*:
 ## Wrapping Asynchronous Functions in [NS]Operation
 
 The approach you've seen thus far to wrapping functionality in `Operation` only works provided you can guarantee that all the work has been completed when the `main()` method returns. This is not the case if you're wrapping asynchronous functions, which return immediately, and return their result at a later point.
 
 `Operation` has support for this, but requires that you manage the state manually. The following KVO properties must now be kept up-to-date with the operation status:
 - `ready`
 - `executing`
 - `finished`
 
 In order to make this task easier, `AsyncOperation` is a custom subclass of `Operation` that handles the state change automatically, and in a slightly more _Swift-like_ manner. This reduces wrapping an asynchronous function to the following:
 
 1. Subclass `AsyncOperation`.
 2. Override `main()` and call your async function.
 3. Change the `state` property of the `AsyncOperation` subclass to `.Finished` in the async callback.
 
 - important:
 Step 3 of these instructions is *extremely* important - it's how the queue responsible for running the operation can tell that it has completed. Otherwise it'll sit uncompleted for eternity.
 */
import UIKit


/*:
 The subclass adds a `state` property, and ensures that the appropriate KVO notifications are sent when the value is updated. This is integral to how `NSOperationQueue` manages its operations
 */
class AsyncOperation: Operation {
  enum State: String {
    case Ready, Executing, Finished
    
    fileprivate var keyPath: String {
      return "is" + rawValue
    }
  }
  
  var state = State.Ready {
    willSet {
      willChangeValue(forKey: newValue.keyPath)
      willChangeValue(forKey: state.keyPath)
    }
    didSet {
      didChangeValue(forKey: oldValue.keyPath)
      didChangeValue(forKey: state.keyPath)
    }
  }
}

/*:
 Each of the state properties inherited from `Operation` are then overridden to defer to the new `state` property.
 
 The `asynchronous` property must be set to `true` to tell the system that you'll be managing the state manually.
 
 You also override `start()` and `cancel()` to wire in the new `state` property.
 */
extension AsyncOperation {
  // NSOperation Overrides
  override var isReady: Bool {
    return super.isReady && state == .Ready
  }
  
  override var isExecuting: Bool {
    return state == .Executing
  }
  
  override var isFinished: Bool {
    return state == .Finished
  }
  
  override var isAsynchronous: Bool {
    return true
  }
  
  override func start() {
    if isCancelled {
      state = .Finished
      return
    }
    main()
    state = .Executing
  }
  
  override func cancel() {
    state = .Finished
  }
}



/*:
 Wrapping an asynchronous function then becomes as simple as overriding the `main()` function, remembering to set the `state` parameter on completion:
 */
class ImageLoadOperation: AsyncOperation {
  var inputName: String?
  var outputImage: UIImage?
  
  override func main() {
    duration {
      simulateAsyncNetworkLoadImage(named: self.inputName) {
        [unowned self] (image) in
        self.outputImage = image
        self.state = .Finished
      }
    }
  }
}

//: This operation can then be used in the same way as any other `Operation`:
let queue = OperationQueue()

let imageLoad = ImageLoadOperation()
imageLoad.inputName = "train_dusk.jpg"

queue.addOperation(imageLoad)

duration {
  queue.waitUntilAllOperationsAreFinished()
}

imageLoad.outputImage


//: [➡ NSOperation Dependencies](@next)
