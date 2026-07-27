package ΔΔpackage-nameΔΔ

object Solution {

  def twoSum(nums: Array[Int], target: Int): Array[Int] = {
    val map = scala.collection.mutable.Map[Int, Int]()

    for ((num, index) <- nums.zipWithIndex) {
      val complement = target - num
      if (map.contains(complement)) {
        return Array(map(complement), index)
      }
      map(num) = index
    }

    Array.emptyIntArray
  }
}

object Main {
  def main(args: Array[String]): Unit = {
    println("🚀 LeetCode Scala Playground")

    val nums = Array(2, 7, 11, 15)
    val target = 9
    val result = Solution.twoSum(nums, target)

    println(s"Result for Two Sum: [${result.mkString(", ")}]")
  }
}
