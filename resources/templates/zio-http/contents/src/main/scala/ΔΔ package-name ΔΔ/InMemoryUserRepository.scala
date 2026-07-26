package ΔΔpackage-nameΔΔ

import zio._

final case class InMemoryUserRepository(state: Ref[Map[String, User]]) extends UserRepository:

  def save(user: User): UIO[Unit] =
    state.update(_.updated(user.id, user))

  def findById(id: String): UIO[Option[User]] =
    state.get.map(_.get(id))

  def findAll: UIO[List[User]] =
    state.get.map(_.values.toList)

  def delete(id: String): UIO[Boolean] =
    state.modify { map =>
      val exists = map.contains(id)
      (exists, map - id)
    }

object InMemoryUserRepository:

  // Constructs atomic state container inside a ZLayer
  val live: ULayer[UserRepository] =
    ZLayer {
      for
        state <- Ref.make(Map.empty[String, User])
      yield InMemoryUserRepository(state)
    }
