/*
  Test to directly generate a pickler for a *nested* arbitrary type (that is,
  a type that has at least one field with an arbitrary non-primitive type),
  and then use the generated pickler to pickle an instance of that type.

  This test directly invokes the implicit macro which generates picklers (it
  doesn't use the implicit class that adds the `pickle` extension method)
*/

import scala.pickling._
import binary._
import reflect.runtime.universe._

package scala.pickling {
  class Custom
}

object Test extends App {

  implicit def genListPickler[T: TypeTag](implicit elemPickler: Pickler[T], pf: PickleFormat): Pickler[List[T]] with Unpickler[List[T]] = new Pickler[List[T]] with Unpickler[List[T]] {
    import reflect.runtime.{ universe => ru }
    import ru._

    type PickleFormatType = PickleFormat
    type PickleBuilderType = PickleBuilder
    type PickleReaderType = PickleReader

    val format: PickleFormat = pf
    val rtm = ru.runtimeMirror(getClass.getClassLoader)

    def pickle(picklee: Any, builder: PickleBuilderType): Unit = {
      val list = picklee.asInstanceOf[List[T]]

      builder.beginEntry(typeOf[Custom], null)

      builder.putField("numElems", b => {
        b.beginEntry(typeOf[Int], list.length)
        b.endEntry()
      })

      for (el <- list) {
        builder.putField("elem", b => {
          b.beginEntry(typeOf[T], el)
          b.endEntry()
        })
      }

      builder.endEntry()
    }
    
    def unpickle(tpe: Type, reader: PickleReaderType): Any = {
      val tpe = reader.readType(rtm) // should be "Custom"
      val r2 = reader.readField("numElems")
      val itpe = r2.readType(rtm)
      val num = r2.readPrimitive(typeOf[Int]).asInstanceOf[Int]
      println(s"original list contained $num elements")

      var currReader: PickleReader = null
      var list = List[T]()
      for (i <- 1 to num) {
        currReader = reader.readField("elem")
        val itpe = currReader.readType(rtm)
        val el = currReader.readPrimitive(typeOf[T]).asInstanceOf[T]
        list = list :+ el
      }

      list
    }
  }

  val intPickler     = implicitly[Pickler[Int]]
  val pf             = implicitly[BinaryPickleFormat]
  val listPicklerRaw = implicitly[Pickler[List[Int]]]

  val l = List[Int](7, 24, 30)

  val builder = pf.createBuilder()
  val listPickler = listPicklerRaw.asInstanceOf[Pickler[_]{ type PickleBuilderType = pf.PickleBuilderType }]
  
  listPickler.pickle(l, builder)
  val pckl = builder.result()
  println(pckl.value.asInstanceOf[Array[Byte]].mkString("[", ",", "]"))

  val listUnpickler = listPicklerRaw.asInstanceOf[Unpickler[_]{ type PickleBuilderType = BinaryPickleBuilder ; type PickleReaderType = BinaryPickleReader }]

  val res = listUnpickler.unpickle(typeOf[Int], pf.createReader(pckl))
  println(res)
}
