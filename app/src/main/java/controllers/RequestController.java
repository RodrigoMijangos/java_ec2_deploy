package controllers;

import org.jetbrains.annotations.NotNull;

import gradle_project.Response;
import io.javalin.http.Context;

public class RequestController{

    public static void getAll(@NotNull Context ctx) throws Exception{
        ctx.result("Este es un response de texto");
    }

    public static void sendData(@NotNull Context ctx){

        try {
            Response body = ctx.bodyAsClass(Response.class);
            //System.out.println(body.getresponse());
            ctx.json(body);
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }

    }

}