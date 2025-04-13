package com.example.pos_app;

import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        POSService service = new POSService();
        try (Scanner scanner = new Scanner(System.in)) {
            int opcion = -1;

            while (true) {
                System.out.println("\n=== POS System ===");
                System.out.println("1. Ver ventas realizadas");
                System.out.println("2. Realizar venta");
                System.out.println("0. Salir");
                System.out.print("Seleccione una opción: ");

                if (scanner.hasNextInt()) {
                    // Limpiar pantalla antes de mostrar el menú
                    System.out.flush();
                    opcion = scanner.nextInt();
                    scanner.nextLine(); // Consumir newline después del número

                    switch (opcion) {
                        case 1:
                            service.clearConsole();
                            service.viewProducts();
                            break;
                        case 2:
                            service.clearConsole();
                            service.realizarVenta(scanner);
                            break;
                        case 0:
                            service.clearConsole();
                            System.out.println("👋 Cerrando sistema POS...");
                            return;
                        default:
                            System.out.println("⚠️ Opción no válida.");
                    }
                } else {
                    System.out.println("❌ Entrada no válida. Por favor ingrese un número.");
                    scanner.nextLine(); // Limpiar entrada incorrecta
                }
            }
        }
    }
}
