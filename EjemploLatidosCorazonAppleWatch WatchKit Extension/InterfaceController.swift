import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var labelLatidos: WKInterfaceLabel!
    @IBOutlet var btnPulsaciones: WKInterfaceButton!
    
    //CONSTANTE DE LA CLASE HKHealthStore, QUE GESTIONA EL ACCESO A LOS DATOS, Y TAMBIÉN PEDIRÁ AUTORIZACIÓN AL USUARIO
    let healthStore = HKHealthStore()
    //CONSTANTE DE LA CLASE HKQuantityType, DECIR LO QUE QUIERO MEDIR HKQuantityTypeIdentifierHeartRate
    let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    //CONSTANTE PARA ASIGNAR LA UNIDAD DE MEDIDA QUE YO QUIERO MOSTRAR
    let heartRateUnit = HKUnit(from: "count/min")
    //VARIABLE ASIGNAR UNA QUERY DE LOS DATOS QUE QUEREMOS OBTENER DE HEALTHKIT
    var heartRateQuery: HKQuery?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        //GUARD PARA VER SI HEALTHKIT ESTÁ DISPONIBLE
        guard HKHealthStore.isHealthDataAvailable() else{
            labelLatidos.setText("No disponible")
            return
        }
        //ASIGNAR UNA COLECCIÓN SET
        let dataTypes = Set([heartRateType])
        
        //SOLICITAR AUTORIZACIÓN AL USUARIO
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (exito, error) -> Void in
            
            //GUARD PARA VER SI SE RECOGEN LOS DATOS CON ÉXITO O NO
            guard exito else{
                self.labelLatidos.setText("No hay datos")
                return
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func btnMedirPulsaciones() {
        //GUARD COMPROBAR SI HAY VALOR NIL
        guard heartRateQuery == nil else {
            
            //PARAR LA QUERY
            healthStore.stop(self.heartRateQuery!)
            
            //CAMBIAR EL TITULO DEL BOTON
            btnPulsaciones.setTitle("Start")
            return
        }
        
        //COMENZAMOS LA QUERY
        heartRateQuery = self.crearQuery()
        
        //EJECUTAMOS LA CONSULTA AL ALMACEN DE HEALTHKIT
        healthStore.execute(self.heartRateQuery!)
        
        //CAMBIAR EL TITULO DEL BOTON
        btnPulsaciones.setTitle("Stop")
    }
    
    //FUNCIÓN HARÁ LA CONSULTA A HEALTHKIT PARA TRAER LOS DATOS, USAREMOS PREDICADO
    func  crearQuery() -> HKQuery{
        
        //CONSTANTE CON EL PREDICADO
        
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictEndDate)
        
        //CREAR UN OBJETO QUERY QUE NOS DEVOLVERÁ LOS DATOS DE HEALTHKIT
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)){(query, muestras, deletedObjects, anchor, error) -> Void in
            
            //LLAMAMOS A UN MÉTODO QUE VA A EXTRAER LAS MUESTRAS DE HEALTHKIT
            self.aniadirMuestras(muestras: muestras)
        }
        
        //ACTUALIZAR LOS DATOS DE LA QUERY, VOLVEMOS A LLAMAR EL MÉTODO
        
        query.updateHandler = {(query, muestras, deletedObjects, anchor, error) -> Void in
            self.aniadirMuestras(muestras: muestras)
        }
        return query
    }
    
    //FUNCIÓN QUE VA A RECOGER LOS DATOS, LAS MUESTRAS Y LAS VA A MOSTRAR EN LAS ETIQUETAS
    func aniadirMuestras (muestras: [HKSample]?){
        
        //EL VALOR DE LA MUESTRA
        guard let muestras = muestras as? [HKQuantitySample] else  {return}
        
        //EL ÚLTIMO ELEMENTO Y LA CANTIDAD
        guard let quantity = muestras.last?.quantity else {return}
        
        //MOSTRAR EL VALOR EN LA ETIQUETA
        labelLatidos.setText("\(quantity.doubleValue(for: heartRateUnit))")
        
    }
    
}
