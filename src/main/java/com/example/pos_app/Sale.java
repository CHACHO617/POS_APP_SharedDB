package com.example.pos_app;

import java.time.LocalDateTime;

public class Sale {
    private int ventaId;

    public Sale(int ventaId, int productoId, int cantidadVendida, String tienda) {
        this.ventaId = ventaId;
        this.productoId = productoId;
        this.cantidadVendida = cantidadVendida;
        this.fecha = LocalDateTime.now();
        this.tienda = tienda;
    }

    public int getVentaId() {
        return ventaId;
    }
    private int productoId;
    private int cantidadVendida;
    private LocalDateTime fecha;
    private String tienda;

    public Sale(int productoId, int cantidadVendida, String tienda) {
        this.productoId = productoId;
        this.cantidadVendida = cantidadVendida;
        this.fecha = LocalDateTime.now();
        this.tienda = tienda;
    }

    public int getProductoId() {
        return productoId;
    }

    public int getCantidadVendida() {
        return cantidadVendida;
    }

    public LocalDateTime getFecha() {
        return fecha;
    }

    public String getTienda() {
        return tienda;
    }
}