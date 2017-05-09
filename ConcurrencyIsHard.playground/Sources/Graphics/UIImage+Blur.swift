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

import UIKit
import Accelerate

extension UIImage {
  public func applyBlur(radius: CGFloat, maskImage: UIImage? = nil) -> UIImage? {
    // Check pre-conditions.
    if (size.width < 1 || size.height < 1) {
      print("*** error: invalid size: \(size.width) x \(size.height). Both dimensions must be >= 1: \(self)")
      return nil
    }
    if self.cgImage == nil {
      print("*** error: image must be backed by a CGImage: \(self)")
      return nil
    }
    if maskImage != nil && maskImage!.cgImage == nil {
      print("*** error: maskImage must be backed by a CGImage: \(maskImage)")
      return nil
    }
    
    let __FLT_EPSILON__ = CGFloat(FLT_EPSILON)
    let screenScale = UIScreen.main.scale
    let imageRect = CGRect(origin: .zero, size: size)
    var effectImage = self
    
    let hasBlur = radius > __FLT_EPSILON__
    
    if hasBlur {
      func createEffectBuffer(context: CGContext) -> vImage_Buffer {
        let data = context.data
        let width = vImagePixelCount(context.width)
        let height = vImagePixelCount(context.height)
        let rowBytes = context.bytesPerRow
        
        return vImage_Buffer(data: data, height: height, width: width, rowBytes: rowBytes)
      }
      
      UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
      let effectInContext = UIGraphicsGetCurrentContext()!
      
      effectInContext.scaleBy(x: 1.0, y: -1.0)
      effectInContext.translateBy(x: 0, y: -size.height)
      effectInContext.draw(self.cgImage!, in: imageRect)
      
      var effectInBuffer = createEffectBuffer(context: effectInContext)
      
      
      
      UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
      let effectOutContext = UIGraphicsGetCurrentContext()!
      
      var effectOutBuffer = createEffectBuffer(context: effectOutContext)
      
      
      if hasBlur {
        // A description of how to compute the box kernel width from the Gaussian
        // radius (aka standard deviation) appears in the SVG spec:
        // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
        //
        // For larger values of 's' (s >= 2.0), an approximation can be used: Three
        // successive box-blurs build a piece-wise quadratic convolution kernel, which
        // approximates the Gaussian kernel to within roughly 3%.
        //
        // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
        //
        // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
        //
        
        let inputRadius = radius * screenScale
        var radius = UInt32(floor(Double(inputRadius * 0.75 * sqrt(2.0 * .pi) + 0.5)))
        if radius % 2 != 1 {
          radius += 1 // force radius to be odd so that the three box-blur methodology works.
        }
        
        let imageEdgeExtendFlags = vImage_Flags(kvImageEdgeExtend)
        
        vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
        vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
        vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, nil, 0, 0, radius, radius, nil, imageEdgeExtendFlags)
      }
      
      effectImage = UIGraphicsGetImageFromCurrentImageContext()!
      
      UIGraphicsEndImageContext()
      UIGraphicsEndImageContext()
    }
    
    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(size, false, screenScale)
    let outputContext = UIGraphicsGetCurrentContext()
    outputContext!.scaleBy(x: 1.0, y: -1.0)
    outputContext!.translateBy(x: 0, y: -size.height)
    
    // Draw base image.
    outputContext!.draw(self.cgImage!, in: imageRect)
    
    // Draw effect image.
    if hasBlur {
      outputContext!.saveGState()
      if let image = maskImage {
        let effectCGImage = effectImage.cgImage!.masking(image.cgImage!)
        if let effectCGImage = effectCGImage {
          effectImage = UIImage(cgImage: effectCGImage)
        }
      }
      outputContext!.draw(effectImage.cgImage!, in: imageRect)
      outputContext!.restoreGState()
    }
    
    // Output image is ready.
    let outputImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return outputImage
  }
}

