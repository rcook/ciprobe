fn main() {
    println!("version: {}", env!("CARGO_PKG_DESCRIPTION"))
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
