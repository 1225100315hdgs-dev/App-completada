enum EstadoToma { pendiente, tomada, omitida }

enum OrigenConfirmacion { notificacion, lista }

enum TipoRecordatorio { inicial, pospuesto }

enum EstadoRecordatorio { programado, enviado, atendido, cancelado }

enum EstadoAlerta { pendiente, enviada, fallida }

enum IndicacionAlimento { antesDeComer, despuesDeComer, indistinto }

/// Cómo se comunicó el cuidador con la persona después de una alerta.
enum MedioContacto { llamada, mensaje, visita }

extension MedioContactoX on MedioContacto {
  String get etiqueta {
    switch (this) {
      case MedioContacto.llamada:
        return 'Llamada';
      case MedioContacto.mensaje:
        return 'Mensaje';
      case MedioContacto.visita:
        return 'Visita';
    }
  }
}
