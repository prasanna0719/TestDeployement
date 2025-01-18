public class PipedrivePersonResponse {
    public Boolean success;
    public PipedriveData data;
    
    public class PipedriveData {
        public Integer id;        // Pipedrive Person ID
        public String name;       // Name of the person
        public String email;      // Email of the person
        public String phone;      // Phone number
    }
}