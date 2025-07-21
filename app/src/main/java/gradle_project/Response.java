package gradle_project;


public class Response{

    int number;
    int response;
    String str;
    boolean created;
    String optional;

    public Response() { }

    public Response(
        int number,
        String str,
        boolean created
    ){
        this.number = number;
        this.str = str;
        this.created = created;
    }
    
    public void setNumber(int number){
        this.number = number;
    }

    public int getNumber(){
        return this.number;
    }

    public void setStr(String str){
        this.str = str;
    }

    public String getStr(){
        return this.str;
    }

    public void setCreated(boolean created){
        this.created = created;
    }

    public boolean isCreated(){
        return this.created;
    }

    public String getOptional(){
        return this.optional;
    }

    public void setOptional(String optional){
        this.optional = optional;
    }

    public void setTandom(String random){
        System.out.println(random);
    }

}
