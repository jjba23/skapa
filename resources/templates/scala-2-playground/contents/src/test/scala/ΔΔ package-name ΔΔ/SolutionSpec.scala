package ΔΔpackage-nameΔΔ

import org.scalatest.funsuite.AnyFunSuite

class SolutionSpec extends AnyFunSuite {

  test("Two Sum: standard case") {
    val nums = Array(2, 7, 11, 15)
    val target = 9
    val expected = Array(0, 1)

    assert(Solution.twoSum(nums, target).toList == expected.toList)
  }

  test("Two Sum: non-adjacent elements") {
    val nums = Array(3, 2, 4)
    val target = 6
    val expected = Array(1, 2)

    assert(Solution.twoSum(nums, target).toList == expected.toList)
  }

  test("Two Sum: duplicate values") {
    val nums = Array(3, 3)
    val target = 6
    val expected = Array(0, 1)

    assert(Solution.twoSum(nums, target).toList == expected.toList)
  }
}
