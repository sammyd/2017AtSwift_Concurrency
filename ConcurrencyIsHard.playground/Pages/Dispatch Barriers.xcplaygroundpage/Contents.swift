//: [⬅ GCD Groups](@previous)

import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

//: ## GCD Barriers
//: When you're using asynchronous calls you need to consider thread safety.
//: Consider the following object:

let nameChangingPerson = Person(firstName: "Alison", lastName: "Anderson")

//: The `Person` class includes a method to change names:

nameChangingPerson.changeName(firstName: "Brian", lastName: "Biggles")
nameChangingPerson.name

//: What happens if you try and use the `changeName(firstName:lastName:)` simulataneously from a concurrent queue?

let workerQueue = DispatchQueue(label: "com.raywenderlich.worker", attributes: .concurrent)
let nameChangeGroup = DispatchGroup()

let nameList = [("Charlie", "Cheesecake"), ("Delia", "Dingle"), ("Eva", "Evershed"), ("Freddie", "Frost"), ("Gina", "Gregory")]

for (idx, name) in nameList.enumerated() {
  workerQueue.async(group: nameChangeGroup) {
    usleep(UInt32(10_000 * idx))
    nameChangingPerson.changeName(firstName: name.0, lastName: name.1)
    print("Current Name: \(nameChangingPerson.name)")
  }
}

nameChangeGroup.notify(queue: DispatchQueue.main) {
  print("Final name: \(nameChangingPerson.name)")
  //PlaygroundPage.current.finishExecution()
}

nameChangeGroup.wait()


//: __Result:__ `nameChangingPerson` has been left in an inconsistent state.


//: ### Dispatch Barrier
//: A barrier allows you add a task to a concurrent queue that will be run in a serial fashion. i.e. it will wait for the currently queued tasks to complete, and prevent any new ones starting.

class ThreadSafePerson: Person {
  let isolationQueue = DispatchQueue(label: "com.raywenderlich.person.isolation", attributes: .concurrent)
  
  override func changeName(firstName: String, lastName: String) {
    isolationQueue.async(flags: .barrier) {
      super.changeName(firstName: firstName, lastName: lastName)
    }
  }
  
  override var name: String {
    return isolationQueue.sync {
      return super.name
    }
  }
}



print("\n=== Threadsafe ===")

let threadSafeNameGroup = DispatchGroup()

let threadSafePerson = ThreadSafePerson(firstName: "Anna", lastName: "Adams")

for (idx, name) in nameList.enumerated() {
  workerQueue.async(group: threadSafeNameGroup) {
    usleep(UInt32(10_000 * idx))
    threadSafePerson.changeName(firstName: name.0, lastName: name.1)
    print("Current threadsafe name: \(threadSafePerson.name)")
  }
}

threadSafeNameGroup.notify(queue: DispatchQueue.main) {
  print("Final threadsafe name: \(threadSafePerson.name)")
  PlaygroundPage.current.finishExecution()
}


//: [➡ Futures](@next)
