package ΔΔpackage-nameΔΔ

import zio._

final case class User(id: String, name: String, email: String)

trait UserRepository:
  def save(user: User): UIO[Unit]
  def findById(id: String): UIO[Option[User]]
  def findAll: UIO[List[User]]
  def delete(id: String): UIO[Boolean]
