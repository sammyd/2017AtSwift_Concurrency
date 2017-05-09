//: [⬅ Dispatch Barriers](@previous)

/*:
 ## Futures
 
 GCD is a great abstraction for concurrent programming, but suffers from unnecessary
 complexity when chaining multiple asynchronous tasks together. This manifests itself
 through a so-called "pyramid-of-doom".
 
 An abstraction popular in the JavaScript community is to use a construct known as a "future" or
 "promise". A future is an object that represents the value that an asynchronous value will
 eventually resolve to. As such you can use a future as if it were a real value, and easily chain
 asynchronous tasks together.
 
 Futures also offer a huge advantage in error handling, through the use of a `Result` type - allowing
 an async operation to either resolve to a value, or an error.
 
 In this treatment of futures, you'll disover how to construct a future, without reference to error
 handling. This will allow you to properly understand the concepts before moving on to more complete
 implementations.
 
 */

import PlaygroundSupport
import Foundation

PlaygroundPage.current.needsIndefiniteExecution = true


/*:
 A `Future` struct generic over the result type. Constructed with an async operation; that is a
 closure that accepts a completion handler as an argument. The completion handler is called once
 the operation is completed, and provides the result `T`.
 
 A `Future` has a `resolve()` method which actually invokes the supplied async oepration, and
 calls the supplied completion handler with the result.
 
 The `then()` method allows chaining of futures - taking a closure which accepts the result of the
 first future and a new callback.
 */

struct Future<T> {
  typealias FutureResultHandler = (T) -> ()
  typealias AsyncOperation = (@escaping FutureResultHandler) -> ()
  
  private let asyncOperation: AsyncOperation
  
  init(asyncOperation: @escaping AsyncOperation) {
    self.asyncOperation = asyncOperation
  }
  
  func resolve(_ handler: @escaping FutureResultHandler) {
    asyncOperation(handler)
  }
  
  func then<U>(_ next: @escaping (_ input: T, _ callback: @escaping (U) -> ()) -> ()) -> Future<U> {
    return Future<U> { (resultHandler) in
      self.resolve { firstResult in
        next(firstResult) { secondResult in
          resultHandler(secondResult)
        }
      }
    }
  }
}


let queue = DispatchQueue(label: "com.razeware.sams-queue")

/*:
 ### Sample Async Operations
 */
// Data load
func loadData(_ callback: @escaping ([Int]) -> ()) {
  queue.async {
    usleep(500_000)
    callback(Array(1...10))
  }
}


// Image load
func loadImages(_ input: [Int], callback: @escaping ([String]) -> ()) {
  queue.async {
    usleep(500_000)
    callback(input.map { String(repeating: "🐠" , count: $0) })
  }
}


// Image Processing
func processImages(_ input: [String], callback: @escaping ([String]) -> ()) {
  queue.async {
    usleep(500_000)
    callback(input.map { $0.replacingOccurrences(of: "🐠🐠🐠🐠", with: "🐙") } )
  }
}

func secondaryProcessing(_ input: [String], callback: @escaping ([String]) -> ()) {
  queue.async {
    usleep(1_000_000)
    callback(input.map { return "💄" + $0 + "🎏"} )
  }
}

/*:
 ### Without Futures
 
 Chaining this operations without futures results in a steady drift across the screen: the
 _pyramid-of-doom_.
 */

loadData { (data) in
  loadImages(data, callback: { (images) in
    processImages(images, callback: { (result) in
      secondaryProcessing(result, callback: { (output) in
        DispatchQueue.main.async {
          print("This is your processed data:")
          for value in output {
            print(value)
          }
        }
      })
    })
  })
}


/*:
 ### With Futures
 
 A lot more readable, a fluent API clearly defining the flow of operations
 */

Future(asyncOperation: loadData)
  .then(loadImages)
  .then(processImages)
  .then(secondaryProcessing)
  .resolve { results in
    DispatchQueue.main.async {
      print(results)
      PlaygroundPage.current.finishExecution()
    }
}


/*:
 -note:
 You'll notice that this looks a lot like the procedure used at the beginning of the workshop with
 Operations. This is because an Operation is pretty-much the same as a future/promise.
 
 As mentioned at the top of this, a more-proper treatment of Futures would also handle errors, via 
 a `Result` enum:
 */

enum Result<T, E:Error> {
  case success(T)
  case failure(E)
}

/*:
 This allows error handling to be combined at the end of the chain of futures, rather than at
 each indvidual step. This is much nicer error handling model.
 
 Futures/Promises are actually just a special case of something known as a *Signal*, used in
 Functional Reactive Programming models. Popular implementations of this model include *RxSwift* and
 *ReactiveCocoa*. Wheras a promise can only represent a single value, a signal represents a stream
 of values, over time. This is great for modelling things such as UI changes, and data changes.
 
 Signals maintain the nice fluent API of creating processing chains, and the attractive error
 handling model.

 ---
 Hope you enjoyed this playground introduction to concurrency on iOS. Any questions please feel free to shout at me on twitter — I'm [@iwantmyrealname](https://twitter.com/iwantmyrealname).
 
 —sam
 
 
 ![Razeware](razeware_64.png)
 
 © Razeware LLC, 2016
 */

