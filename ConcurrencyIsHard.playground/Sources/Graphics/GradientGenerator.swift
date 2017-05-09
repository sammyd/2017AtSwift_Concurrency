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

func topAndBottomGradient(size: CGSize, clearLocations: [CGFloat] = [0.35, 0.65], innerIntensity: CGFloat = 0.5) -> UIImage {
  
  let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)

  let colors = [
    .white,
    UIColor(white: innerIntensity, alpha: 1.0),
    .black,
    UIColor(white: innerIntensity, alpha: 1.0),
    .white
    ].map { $0.cgColor }
  let colorLocations : [CGFloat] = [0, clearLocations[0], (clearLocations[0] + clearLocations[1]) / 2.0, clearLocations[1], 1]
  
  let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceGray(), colors: colors as CFArray, locations: colorLocations)
  
  let startPoint = CGPoint(x: 0, y: 0)
  let endPoint = CGPoint(x: 0, y: size.height)
  
  context?.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions())
  let cgImage = context!.makeImage()
  
  return UIImage(cgImage: cgImage!)

}

