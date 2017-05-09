/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


import Foundation

open class AsyncOperation: Operation {
  public enum State: String {
    case Ready, Executing, Finished
    
    fileprivate var keyPath: String {
      return "is" + rawValue
    }
  }
  
  public var state = State.Ready {
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


extension AsyncOperation {
  // Operation Overrides
  override open var isReady: Bool {
    return super.isReady && state == .Ready
  }
  
  override open var isExecuting: Bool {
    return state == .Executing
  }
  
  override open var isFinished: Bool {
    return state == .Finished
  }
  
  override open var isAsynchronous: Bool {
    return true
  }
  
  override open func start() {
    if isCancelled {
      state = .Finished
      return
    }
    
    main()
    state = .Executing
  }
  
  open override func cancel() {
    state = .Finished
  }
}

