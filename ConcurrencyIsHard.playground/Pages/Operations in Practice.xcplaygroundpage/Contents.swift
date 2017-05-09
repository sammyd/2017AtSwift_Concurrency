//: [⬅ Chaining NSOperations](@previous)
/*:
 ## [NS]Operations in Practice
 
 You've seen how powerful `Operation` is, but not really seen it fix a real-world problem.
 
 This playground page demonstrates how you can use `Operation` to load and filter images for display in a table view, whilst maintaining the smooth scroll effect you expect from table views.
 
 This is a common problem, and comes from the fact that if you attempt expensive operations synchronously, you'll block the main queue (thread). Since this is used for rendering the UI, you cause your app to become unresponsive - temporarily freezing.
 
 The solution is to move data loading off into the background, which can be achieved easily with `Operation`.
 
 */
import UIKit
import PlaygroundSupport

let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 720))
tableView.register(ImageCell.self, forCellReuseIdentifier: "ImageCell")
PlaygroundPage.current.liveView = tableView
tableView.rowHeight = 250


//: `ImageProvider` is a class that is responsible for loading and processing an image. It creates the relevant operations, chains them together, pops them on a queue and then ensures that the output is passed back appropriately
class ImageProvider {
  let queue = OperationQueue()
  var loadedImage: UIImage?
  var completion: ((UIImage?) -> ())?
  
  init(imageName: String) {
    let loadOp = ImageLoadOperation()
    let tiltShiftOp = TiltShiftOperation()
    let outputOp = ImageOutputOperation()
    
    loadOp.inputName = imageName
    outputOp.completion = { [unowned self] image in
      self.loadedImage = image
      self.completion?(image)
    }
  
    loadOp |> tiltShiftOp |> outputOp
    
    queue.addOperations([loadOp, tiltShiftOp, outputOp], waitUntilFinished: false)
  }
  
  func cancel() {
    queue.cancelAllOperations()
  }
}

//: `DataSource` is a class that represents the table's datasource and delegate
class DataSource: NSObject {
  var imageNames = [String]()
  var imageProviders = [IndexPath : ImageProvider]()
}

//: Possibly the simplest implementation of `UITableViewDataSource`:
extension DataSource: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return imageNames.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return tableView.dequeueReusableCell(withIdentifier: "ImageCell", for: indexPath)
  }
}

extension DataSource: UITableViewDelegate {
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if let cell = cell as? ImageCell {
      if let provider = imageProviders[indexPath] {
        if let image = provider.loadedImage {
          cell.transitionToImage(image: image)
          self.imageProviders.removeValue(forKey: indexPath)
        } else {
          provider.completion = { [unowned self] (image) in
            cell.transitionToImage(image: image)
            self.imageProviders.removeValue(forKey: indexPath)
          }
        }
      } else {
        let provider = ImageProvider(imageName: imageNames[indexPath.row])
        provider.completion = { [unowned self] (image) in
          cell.transitionToImage(image: image)
          self.imageProviders.removeValue(forKey: indexPath)
        }
        imageProviders[indexPath] = provider
      }
    }
  }
  
  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if let cell = cell as? ImageCell {
      cell.transitionToImage(image: .none)
    }
    if let provider = imageProviders[indexPath] {
      provider.cancel()
      imageProviders.removeValue(forKey: indexPath)
    }
  }
}

extension DataSource: UITableViewDataSourcePrefetching {
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    for indexPath in indexPaths {
      let provider = ImageProvider(imageName: imageNames[indexPath.row])
      imageProviders[indexPath] = provider
    }
  }
  
  func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
    for indexPath in indexPaths {
      if let provider = imageProviders[indexPath] {
        provider.cancel()
        imageProviders.removeValue(forKey: indexPath)
      }
    }
  }
}

//: Create a datasource and provide a list of images to display
let ds = DataSource()
ds.imageNames = ["dark_road_small.jpg", "train_day.jpg", "train_dusk.jpg", "train_night.jpg", "dark_road_small.jpg", "train_day.jpg", "train_dusk.jpg", "train_night.jpg", "dark_road_small.jpg", "train_day.jpg", "train_dusk.jpg", "train_night.jpg", "dark_road_small.jpg", "train_day.jpg", "train_dusk.jpg", "train_night.jpg"]

tableView.dataSource = ds
tableView.delegate = ds
tableView.prefetchDataSource = ds

/*:
 - note:
 This implementation for a table view is not complete, but instead meant to demonstrate how you can use `NSOperation` to improve the scrolling performance.
 
 [➡ Grand Central Dispatch](@next)
 */
