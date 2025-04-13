package com.example.pos_app;

import java.sql.*;
import java.util.Scanner;

public class POSService {

    // Método para ver los productos y las ventas realizadas
    public void viewProducts() {
        String query = "SELECT * FROM VistaPOSProductosVentas"; // Consulta a la vista que une productos y ventas
        try (Connection conn = DBConnection.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(query)) {

            System.out.println("=== Ventas Realizadas ===");
            while (rs.next()) {
                System.out.printf("Producto ID: %d | Nombre: %s | Precio: %.2f | Cantidad Vendida: %d | Fecha Venta: %s\n",
                        rs.getInt("id_producto"),
                        rs.getString("nombre"),
                        rs.getDouble("precio"),
                        rs.getInt("cantidad_vendida"),
                        rs.getDate("fecha_venta")
                );
            }
        } catch (SQLException e) {
            System.err.println("Error al consultar productos:");
            e.printStackTrace();
        }
    }

    // Método para realizar una venta
    public void realizarVenta(Scanner scanner) {
        try {
            System.out.print("Ingrese ID de producto: ");
            int producto_id = scanner.nextInt();

            System.out.print("Ingrese cantidad vendida: ");
            int cantidad = scanner.nextInt();

            scanner.nextLine(); // Consume the newline character left by nextInt()

            System.out.println("Seleccione tienda:\n1: Quito\n2: Guayaquil\n3: Cuenca");
            String tienda = scanner.nextLine();
            switch (tienda) {
                case "1":
                    tienda = "Quito";
                    break;
                case "2":
                    tienda = "Guayaquil";
                    break;
                case "3":
                    tienda = "Cuenca";
                    break;
                default:
                    System.out.println(" Tienda no válida. Operación cancelada.");
                    return;
            }

            // Realizar la venta y actualizar inventario en una transacción
            try (Connection conn = DBConnection.getConnection()) {
                conn.setAutoCommit(false); // Comenzar la transacción

                // Paso previo: validar que el producto existe y tiene stock en esa tienda
                String checkInventory = "SELECT cantidad_disponible FROM Inventario WHERE id_producto_inv = ? AND ubicacion_tienda = ?";
                try (PreparedStatement checkStmt = conn.prepareStatement(checkInventory)) {
                    checkStmt.setInt(1, producto_id);
                    checkStmt.setString(2, tienda);

                    ResultSet rs = checkStmt.executeQuery();

                    if (!rs.next()) {
                        System.out.println("El producto no está disponible en esa ubicación.");
                        return;
                    } else if (rs.getInt("cantidad_disponible") < cantidad) {
                        System.out.println("Stock insuficiente en esa tienda.");
                        return;
                    }
                }

                // Insertar la venta
                String insertVenta = "INSERT INTO Ventas (id_producto, cantidad_vendida, fecha_venta, tienda_origen) VALUES (?, ?, GETDATE(), ?)";
                try (PreparedStatement ps = conn.prepareStatement(insertVenta)) {
                    ps.setInt(1, producto_id);
                    ps.setInt(2, cantidad);
                    ps.setString(3, tienda);
                    ps.executeUpdate();
                }

                conn.commit(); // Confirmar los cambios de la transacción
                System.out.println("✅ Venta realizada exitosamente.");
            } catch (SQLException e) {
                System.err.println("❌ Error al procesar la venta:");
                e.printStackTrace();
            }
        } catch (Exception e) {
            System.err.println("❌ Entrada no válida.");
            scanner.nextLine(); // Limpiar cualquier entrada incorrecta en el buffer
        }
    }

    public void clearConsole() {
        System.out.print("\033[H\033[2J");
        System.out.flush();
    }

}
